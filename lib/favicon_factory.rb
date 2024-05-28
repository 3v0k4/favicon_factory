# frozen_string_literal: true

require_relative "favicon_factory/version"
require "tty/which"
require "tty/option"

autoload(:MiniMagick, "mini_magick")
autoload(:Vips, "vips")

module FaviconFactory
  Params = Data.define(:favicon_svg, :background) do
    def dir
      File.dirname(favicon_svg)
    end
  end

  class Command
    include TTY::Option

    usage do
      program "favicon_factory"
      no_command

      desc <<~DESC
        `favicon_factory` generates from an SVG the minimal set of icons needed by modern browsers.

        The source SVG is ideal for [modern browsers](https://caniuse.com/link-icon-svg). And it may contain a `<style>` tag with `@media (prefers-color-scheme: dark)` to support light/dark themes, which is ignored when generating favicons.

        Icons will be generated in the same folder as the source SVG unless already existing:

        - `favicon.ico` (32x32) for legacy browsers; serve it from `/favicon.ico` because tools, like RSS readers, just look there.
        - `apple-touch-icon.png` (180x180) for Apple devices when adding a webpage to the home screen; a background and a padding around the icon is applied to make it look pretty.
        - `manifest.webmanifest` that includes `icon-192.png` and `icon-512.png` for Android devices; the former for display on the home screen, and the latter for the splash screen while the PWA is loading.
      DESC

      example "favicon_factory path/to/favicon.svg"
      example "favicon_factory --background red path/to/favicon.svg"
      example "favicon_factory --background #000000 path/to/favicon.svg"
    end

    argument :favicon_svg do
      name "favicon_svg"
      desc "Path to the favicon.svg"
    end

    option :background do
      short "-b"
      long "--background string"
      default "#ffffff"
      desc "Background hex color for apple-touch-icon.png"
    end

    flag :help do
      short "-h"
      long "--help"
      desc "Print usage"
    end
  end

  class Cli
    def self.call
      adapter = BaseAdapter.find
      if adapter.nil?
        stderr.puts "Error: Neither vips or imagemagick found, install one"
        exit 1
      end
      exit new(adapter: adapter, argv: ARGV, file: File, stderr: $stderr).call
    end

    def initialize(adapter:, argv:, file:, stderr:)
      @adapter = adapter
      @argv = argv
      @file = file
      @stderr = stderr
    end

    def call
      params, status = parse(argv)
      return status if status >= 0

      adapter.new(file: file, params: params, stderr: stderr).create_icons
      0
    end

    private

    attr_reader :stderr, :file, :adapter, :argv

    def parse(argv)
      command = Command.new.parse(argv)
      params = command.params
      return exit_message(0, command.help) if params.fetch(:help) == true
      return exit_message(1, params.errors.summary) if params.errors.any?

      params = params.to_h
      favicon_svg = params.fetch(:favicon_svg)
      return exit_message(1, "Error: #{favicon_svg} does not end with .svg") unless favicon_svg.end_with?(".svg")
      return exit_message(1, "Error: #{favicon_svg} does not exist") unless file.exist?(favicon_svg)

      background = params.fetch(:background)
      unless hex?(background)
        return exit_message(1, "Error: #{background} is not a valid color, use a hex value like #0099ff")
      end

      [Params.new(favicon_svg: favicon_svg, background: background), -1]
    end

    def hex?(string)
      string = string.delete_prefix("#")
      string.split("").all? { |char| char.match?(/^[0-9a-fA-F]$/) }
    end

    def exit_message(status, message)
      stderr.puts message
      [nil, status]
    end
  end

  class BaseAdapter
    class << self
      def find
        if TTY::Which.which("vips") || TTY::Which.which("libvips")
          VipsAdapter
        elsif TTY::Which.which("magick") || TTY::Which.which("convert")
          ImageMagickAdapter
        end
      end
    end

    def initialize(file:, params:, stderr:)
      @file = file
      @params = params
      @stderr = stderr
    end

    def create_icons
      create_by_name
        .keys
        .map { |name| Thread.new { create(name, params) } }
        .each(&:join)

      stderr.puts <<~TEXT
        Info: Add the following to the `<head>`
          <!-- favicons generated with the favicon_factory gem -->
          <link rel="icon" href="/favicon.svg" type="image/svg+xml">
          <link rel="icon" href="/favicon.ico" sizes="32x32">
          <link rel="apple-touch-icon" href="/apple-touch-icon.png">
          <link rel="manifest" href="/manifest.webmanifest">
      TEXT
    end

    private

    attr_reader :params, :stderr, :file

    def create(name, params)
      path = file.join(params.dir, name)
      if file.exist?(path)
        stderr.puts "Info: Skipping #{path} because it already exists"
        return
      end

      stderr.puts "Info: Generating #{path}"
      create_by_name.fetch(name).call(path, params)
    end

    def create_by_name
      {
        "favicon.ico" => method(:ico!),
        "icon-192.png" => method(:png_192!),
        "icon-512.png" => method(:png_512!),
        "apple-touch-icon.png" => method(:touch!),
        "manifest.webmanifest" => method(:manifest!)
      }
    end

    def png_192!(path, params)
      png!(path, params, 192)
    end

    def png_512!(path, params)
      png!(path, params, 512)
    end

    def manifest!(path, _params)
      file.write(path, <<~MANIFEST)
        {
          "icons": [
            { "src": "/icon-192.png", "type": "image/png", "sizes": "192x192" },
            { "src": "/icon-512.png", "type": "image/png", "sizes": "512x512" }
          ]
        }
      MANIFEST
    end
  end

  class VipsAdapter < BaseAdapter
    def ico!(path, params)
      png = Vips::Image.thumbnail(params.favicon_svg, 32).write_to_buffer(".png")
      # https://www.meziantou.net/creating-ico-files-from-multiple-images-in-dotnet.htm
      ico = [0, 1, 1].pack("S<*") + [32, 32, 0, 0].pack("C*") + [1, 32].pack("S<*") + [png.size, 22].pack("L<*") + png
      file.write(path, ico)
    end

    def png!(path, params, size)
      Vips::Image.thumbnail(params.favicon_svg, size).write_to_file(path)
    end

    def touch!(path, params)
      svg = Vips::Image.thumbnail(params.favicon_svg, 160).gravity("centre", 180, 180)
      image = square(180, params.background).composite(svg, :over)
      image.write_to_file(path)
    end

    private

    def square(size, hex)
      pixel = (Vips::Image.black(1, 1) + hex2rgb(hex)).cast(:uchar)
      pixel.embed 0, 0, size, size, extend: :copy
    end

    def hex2rgb(hex)
      hex = hex.delete_prefix("#")
      r = hex[0..1].to_i(16)
      g = hex[2..3].to_i(16)
      b = hex[4..5].to_i(16)
      [r, g, b]
    end
  end

  class ImageMagickAdapter < BaseAdapter
    SVG_DENSITY = 1_000

    def initialize(**)
      super
      stderr.puts "Warn: Install imagemagick v7 for best results, using v6" unless MiniMagick.imagemagick7?
      stderr.puts "Warn: Inkscape not found, install it for best results" unless TTY::Which.which("inkscape")
    end

    def ico!(path, params)
      MiniMagick::Tool::Convert.new do |convert|
        convert.density(SVG_DENSITY).background("none")
        convert << params.favicon_svg
        convert.resize("32x32")
        convert << path
      end
    end

    def png!(path, params, size)
      MiniMagick::Tool::Convert.new do |convert|
        convert.density(SVG_DENSITY).background("none")
        convert << params.favicon_svg
        convert.resize("#{size}x#{size}")
        convert << path
      end
    end

    def touch!(path, params)
      MiniMagick::Tool::Convert.new do |convert|
        convert.density(SVG_DENSITY).background(params.background)
        convert << params.favicon_svg
        convert.resize("160x160").gravity("center").extent("180x180")
        convert << path
      end
    end
  end
end
