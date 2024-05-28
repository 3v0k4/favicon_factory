# frozen_string_literal: true

require "test_helper"
require "stringio"

class TestFaviconFactory < Minitest::Test
  def test__with_no_args__it_errors_and_prints_usage
    argv = []
    stderr = StringIO.new
    status = FaviconFactory::Cli.new(argv: argv, stderr: stderr, file: File, adapter: nil).call

    assert_equal 1, status
    assert_match Regexp.new("Error: argument 'favicon_svg' must be provided"), stderr.string
  end

  def test__with_arg_not_being_an_svg__it_errors
    argv = ["one"]
    stderr = StringIO.new
    status = FaviconFactory::Cli.new(argv: argv, stderr: stderr, file: File, adapter: nil).call

    assert_equal 1, status
    assert_match Regexp.new("Error: one does not end with .svg"), stderr.string
  end

  def test__with_non_existing_svg__it_errors
    argv = ["one.svg"]
    stderr = StringIO.new
    status = FaviconFactory::Cli.new(argv: argv, stderr: stderr, file: File, adapter: nil).call

    assert_equal 1, status
    assert_match Regexp.new("Error: one.svg does not exist"), stderr.string
  end

  def test__it_prints_help
    ["--help", "-h"].each do |flag|
      argv = [flag]
      stderr = StringIO.new
      status = FaviconFactory::Cli.new(argv: argv, stderr: stderr, file: File, adapter: nil).call

      assert_equal 0, status
      assert_match Regexp.new("Usage:"), stderr.string
    end
  end

  def test__with_invalid_background__it_errors
    with_svg do |_dir, path|
      argv = ["--background", "blue", path]
      stderr = StringIO.new
      status = FaviconFactory::Cli.new(argv: argv, stderr: stderr, file: File, adapter: nil).call

      assert_equal 1, status
      assert_match Regexp.new("Error: blue is not a valid color, use a hex value like #0099ff"), stderr.string
    end
  end

  def test__vips__with_existing_files__it_skips
    with_svg do |dir, path|
      TARGETS.each { FileUtils.touch(File.join(dir, _1)) }
      argv = [path]
      stderr = StringIO.new
      status = FaviconFactory::Cli.new(argv: argv, stderr: stderr, file: File, adapter: TestAdapter).call

      assert_equal 0, status
      TARGETS.each do |name|
        assert_match Regexp.new("Info: Skipping #{File.join(dir, name)} because it already exists"), stderr.string
      end
    ensure
      TARGETS.each { FileUtils.rm(File.join(dir, _1)) }
    end
  end

  def test__vips__it_uses_the_background_option
    called = 0

    TestAdapter.class_eval do
      alias_method :touch_!, :touch!

      define_method(:touch!) do |*|
        called += 1
        raise(params.background) if params.background != "#0099ff"
      end
    end

    with_svg do |_dir, path|
      argv = ["--background", "#0099ff", path]
      status = FaviconFactory::Cli.new(argv: argv, stderr: StringIO.new, file: File, adapter: TestAdapter).call

      assert_equal 0, status
    end

    with_svg do |_dir, path|
      argv = [path, "--background=#0099ff"]
      status = FaviconFactory::Cli.new(argv: argv, stderr: StringIO.new, file: File, adapter: TestAdapter).call

      assert_equal 0, status
    end

    with_svg do |_dir, path|
      argv = [path, "-b", "#0099ff"]
      status = FaviconFactory::Cli.new(argv: argv, stderr: StringIO.new, file: File, adapter: TestAdapter).call

      assert_equal 0, status
    end

    assert_equal 3, called
  ensure
    TestAdapter.class_eval do
      remove_method(:touch!)
      alias_method :touch!, :touch_!
    end
  end
end
