module FaviconFactory
  class ImageMagickAdapter < BaseAdapter
    SVG_DENSITY = 1_000

    def initialize(**)
      super
      stderr.puts "Warn: Install imagemagick v7 for best results, using v6" unless MiniMagick.imagemagick7?
    end

    def ico!(path, params)
      generate 32, "none", path
    end

    def png!(path, params, size)
      generate size, "none", path
    end

    def touch!(path, params)
      size = 180
      generate(160, params.background, path) do |convert|
        convert.gravity("center").extent("#{size}x#{size}")
      end
    end

    def mask!(path, params)
      size = 512
      generate(409, params.background, path) do |convert|
        convert.gravity("center").extent("#{size}x#{size}")
      end
    end

    private

    def generate(size, background, path)
      MiniMagick::Tool::Convert.new do |convert|
        convert.density(SVG_DENSITY).background(background)
        convert << params.favicon_svg
        convert.resize("#{size}x#{size}")
        if block_given?
          convert = yield(convert)
        end
        convert << path
      end
    end
  end
end
