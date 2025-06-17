# frozen_string_literal: true

require "vips"

module FaviconFactory
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

    def mask!(path, params)
      svg = Vips::Image.thumbnail(params.favicon_svg, 409).gravity("centre", 512, 512)
      image = square(512, params.background).composite(svg, :over)
      image.write_to_file(path)
    end

    private

    def square(size, hex)
      pixel = (Vips::Image.black(1, 1) + hex2rgb(hex)).cast(:uchar)
      pixel.embed(0, 0, size, size, extend: :copy)
    end

    def hex2rgb(hex)
      hex = hex.delete_prefix("#")
      r = hex[0..1].to_i(16)
      g = hex[2..3].to_i(16)
      b = hex[4..5].to_i(16)
      [r, g, b]
    end
  end
end
