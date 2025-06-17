# frozen_string_literal: true

require "mini_magick"

module FaviconFactory
  class ImageMagickAdapter < BaseAdapter
    SVG_DENSITY = 1_000

    def initialize(**)
      super
      stderr.puts "Warn: Install imagemagick v7 for best results, using v6" unless MiniMagick.imagemagick7?
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
        convert.resize("160x160")
        convert.gravity("center").extent("180x180")
        convert << path
      end
    end

    def mask!(path, params)
      MiniMagick::Tool::Convert.new do |convert|
        convert.density(SVG_DENSITY).background(params.background)
        convert << params.favicon_svg
        convert.resize("409x409")
        convert.gravity("center").extent("512x512")
        convert << path
      end
    end
  end
end
