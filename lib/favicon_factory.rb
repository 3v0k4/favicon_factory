# frozen_string_literal: true

require_relative "favicon_factory/version"
require "mini_magick"
require "tty/which"
require "tty/option"

module FaviconFactory
  SVG_DENSITY = 1_000

  Params = Data.define(:favicon_svg, :background) do
    def dir
      File.dirname(favicon_svg)
    end
  end

  PngParams = Data.define(:favicon_svg, :background, :size) do
    def self.from_params(size, params)
      new(**params.to_h, size: size)
    end

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
      default "white"
      desc "Background color for apple-touch-icon.png"
    end

    flag :help do
      short "-h"
      long "--help"
      desc "Print usage"
    end
  end

  class Cli
    def self.call
      exit new(ARGV, $stderr).call
    end

    attr_reader :stderr

    def initialize(argv, stderr)
      @argv = argv
      @stderr = stderr
    end

    def call
      stderr.puts "imagemagick v7 not found, please install for best results" unless MiniMagick.imagemagick7?
      stderr.puts "inkscape not found, install inkscape for best results" unless TTY::Which.which("inkscape")

      params, status = parse(@argv)
      return status if status >= 0

      [
        Thread.new { create("favicon.ico", params) },
        Thread.new { create("icon-192.png", PngParams.from_params(192, params)) },
        Thread.new { create("icon-512.png", PngParams.from_params(512, params)) },
        Thread.new { create("apple-touch-icon.png", params) },
        Thread.new { create("manifest.webmanifest", params) }
      ]
        .each(&:join)

      stderr.puts <<~TEXT
        Info: Add the following to the `<head>`
          <!-- favicons generated with the favicon_factory gem -->
          <link rel="icon" href="/favicon.svg" type="image/svg+xml">
          <link rel="icon" href="/favicon.ico" sizes="32x32">
          <link rel="apple-touch-icon" href="/apple-touch-icon.png">
          <link rel="manifest" href="/manifest.webmanifest">
      TEXT

      0
    end

    private

    def parse(argv)
      command = Command.new.parse(argv)
      params = command.params
      return exit_message(0, command.help) if params.fetch(:help) == true
      return exit_message(1, params.errors.summary) if params.errors.any?

      params = params.to_h
      favicon_svg = params.fetch(:favicon_svg)
      return exit_message(1, "Error: #{favicon_svg} does not end with .svg") unless favicon_svg.end_with?(".svg")
      return exit_message(1, "Error: #{favicon_svg} does not exist") unless File.exist?(favicon_svg)

      [Params.new(favicon_svg: favicon_svg, background: params.fetch(:background)), -1]
    end

    def exit_message(status, message)
      stderr.puts message
      [nil, status]
    end

    def create(name, params)
      path = File.join(params.dir, name)
      if File.exist?(path)
        stderr.puts "Info: Skipping #{path} because it already exists"
        return
      end

      stderr.puts "Info: Generating #{path}"
      create_by_name.fetch(name).call(path, params)
    end

    def create_by_name
      {
        "favicon.ico" => method(:ico!),
        "icon-192.png" => method(:png!),
        "icon-512.png" => method(:png!),
        "apple-touch-icon.png" => method(:touch!),
        "manifest.webmanifest" => method(:manifest!)
      }
    end

    def ico!(path, params)
      MiniMagick::Tool::Convert.new do |convert|
        convert.density(SVG_DENSITY).background("none")
        convert << params.favicon_svg
        convert.resize("32x32")
        convert << path
      end
    end

    def png!(path, params)
      MiniMagick::Tool::Convert.new do |convert|
        convert.density(SVG_DENSITY).background("none")
        convert << params.favicon_svg
        convert.resize("#{params.size}x#{params.size}")
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

    def manifest!(path, _params)
      File.write(path, <<~MANIFEST)
        {
          "icons": [
            { "src": "/icon-192.png", "type": "image/png", "sizes": "192x192" },
            { "src": "/icon-512.png", "type": "image/png", "sizes": "512x512" }
          ]
        }
      MANIFEST
    end
  end
end
