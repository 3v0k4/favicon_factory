# frozen_string_literal: true

module FaviconFactory
  Params = Data.define(:favicon_svg, :background) do
    def dir
      File.dirname(favicon_svg)
    end
  end

  class Cli
    def self.call
      exit new(argv: ARGV, file: File, stderr: $stderr).call
    end

    def initialize(argv:, file:, stderr:, find_adapter: -> { BaseAdapter.find })
      @argv = argv
      @file = file
      @stderr = stderr
      @find_adapter = find_adapter
    end

    def call
      code, message = catch(:exit) do
        adapter = try_find_adapter
        params = try_parse(argv)
        adapter.new(file: file, params: params, stderr: stderr).create_icons
        [0, nil]
      end

      stderr.puts message unless message.nil?
      code
    end

    private

    attr_reader :stderr, :file, :find_adapter, :argv

    def try_find_adapter
      adapter = find_adapter.call
      throw(:exit, [1, "Error: Neither vips or imagemagick found, install one"]) if adapter.nil?
      adapter
    end

    def try_parse(argv)
      command = Command.new.parse(argv)
      params = command.params
      throw(:exit, [0, command.help]) if params.fetch(:help) == true
      throw(:exit, [1, params.errors.summary]) if params.errors.any?

      favicon_svg = params.fetch(:favicon_svg)
      throw(:exit, [1, "Error: #{favicon_svg} does not end with .svg"]) unless favicon_svg.end_with?(".svg")
      throw(:exit, [1, "Error: #{favicon_svg} does not exist"]) unless file.exist?(favicon_svg)

      background = params.fetch(:background)
      throw(:exit, [1, "Error: #{background} is not a valid color, use a hex value like #0099ff"]) unless hex?(background)

      Params.new(favicon_svg: favicon_svg, background: background)
    end

    def hex?(string)
      string = string.delete_prefix("#")
      string.chars.all? { |char| char.match?(/^[0-9a-fA-F]$/) }
    end
  end
end
