# frozen_string_literal: true

require_relative "favicon_factory/version"
require_relative "favicon_factory/command"
require_relative "favicon_factory/cli"
require_relative "favicon_factory/base_adapter"

module FaviconFactory
  autoload(:ImageMagickAdapter, "favicon_factory/image_magick_adapter")
  autoload(:VipsAdapter, "favicon_factory/vips_adapter")
end
