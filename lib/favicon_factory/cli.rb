# frozen_string_literal: true

module FaviconFactory
  Params = Data.define(:favicon_svg, :background) do
    def dir
      File.dirname(favicon_svg)
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
end
