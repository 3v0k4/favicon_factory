# frozen_string_literal: true

module FaviconFactory
  class VipsAdapter < BaseAdapter
    def ico!(path, params)
      png = Vips::Image.thumbnail(params.favicon_svg, 32).write_to_buffer(".png")
      # https://www.meziantou.net/creating-ico-files-from-multiple-images-in-dotnet.htm
      ico = [0, 1, 1].pack("S<*") + [32, 32, 0, 0].pack("C*") + [1, 32].pack("S<*") + [png.size, 22].pack("L<*") + png
      file.write(path, ico)
    end

    def png!(path, params, size)
      generate(params.favicon_svg, size, path)
    end

    def touch!(path, params)
      size = 180
      generate(params.favicon_svg, 160, path) do |image|
        image = image.gravity("centre", size, size)
        pixel = (Vips::Image.black(1, 1) + hex2rgb(params.background)).cast(:uchar)
        pixel.embed(0, 0, size, size, extend: :copy).composite(image, :over)
      end
    end

    def mask!(path, params)
      size = 512
      generate(params.favicon_svg, 409, path) do |image|
        image = image.gravity("centre", size, size)
        pixel = (Vips::Image.black(1, 1) + hex2rgb(params.background)).cast(:uchar)
        pixel.embed(0, 0, size, size, extend: :copy).composite(image, :over)
      end
    end

    private

    def generate(svg, size, path)
      image = Vips::Image.thumbnail(svg, size)
      if block_given?
        image = yield(image)
      end
      image.write_to_file(path)
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
