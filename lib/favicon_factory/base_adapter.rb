require "tty/which"

module FaviconFactory
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
        "icon-mask.png" => method(:png_mask!),
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

    def png_mask!(path, params)
      mask!(path, params)
    end

    def manifest!(path, _params)
      require "json"
      data = {
        icons: [
          { src: "/icon-192.png", type: "image/png", sizes: "192x192" },
          { src: "/icon-512.png", type: "image/png", sizes: "512x512" },
          { src: "/icon-mask.png", type: "image/png", sizes: "512x512", purpose: "maskable" },
        ]
      }
      file.write(path, JSON.pretty_generate(data))
    end
  end
end
