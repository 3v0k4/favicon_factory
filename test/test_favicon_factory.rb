# frozen_string_literal: true

require "test_helper"
require "stringio"
require "open3"

class TestFaviconFactory < Minitest::Test
  TARGETS = [
    "favicon.ico",
    "icon-192.png",
    "icon-512.png",
    "apple-touch-icon.png",
    "manifest.webmanifest"
  ].freeze

  def setup
    FaviconFactory.module_eval do
      remove_const(:SVG_DENSITY)
      const_set(:SVG_DENSITY, 1) # make tests faster
    end
  end

  def test_e2e__with_existing_svg__it_succeeds
    with_svg do |dir, path|
      _, stderr, status = Open3.capture3("bundle exec exe/favicon_factory #{path}")

      assert_equal 0, status.exitstatus
      assert_match Regexp.new("Info: Add the following to the `<head>`"), stderr
      TARGETS.each do |name|
        path = File.join(dir, name)
        assert_match Regexp.new("Info: Generating #{path}"), stderr
        assert_path_exists path
      end
    end
  end

  def test__with_no_args__it_exits_1_and_prints_usage
    args = []
    stderr = StringIO.new
    status = FaviconFactory::Cli.new(args, stderr).call

    assert_equal 1, status
    assert_match Regexp.new("Error: argument 'favicon_svg' must be provided"), stderr.string
  end

  def test__with_arg_not_being_an_svg__it_errors
    args = ["one"]
    stderr = StringIO.new
    status = FaviconFactory::Cli.new(args, stderr).call

    assert_equal 1, status
    assert_match Regexp.new("Error: one does not end with .svg"), stderr.string
  end

  def test__with_non_existing_svg__it_errors
    args = ["one.svg"]
    stderr = StringIO.new
    status = FaviconFactory::Cli.new(args, stderr).call

    assert_equal 1, status
    assert_match Regexp.new("Error: one.svg does not exist"), stderr.string
  end

  def test__it_prints_help
    ["--help", "-h"].each do |flag|
      args = [flag]
      stderr = StringIO.new
      status = FaviconFactory::Cli.new(args, stderr).call

      assert_equal 0, status
      assert_match Regexp.new("Usage:"), stderr.string
    end
  end

  def test__with_existing_files__it_skips
    with_svg do |dir, path|
      TARGETS.each { FileUtils.touch(File.join(dir, _1)) }
      args = [path]
      stderr = StringIO.new
      status = FaviconFactory::Cli.new(args, stderr).call

      assert_equal 0, status
      TARGETS.each do |name|
        assert_match Regexp.new("Info: Skipping #{File.join(dir, name)} because it already exists"), stderr.string
      end
    ensure
      TARGETS.each { FileUtils.rm(File.join(dir, _1)) }
    end
  end

  def test__it_uses_the_background_option
    testable_call = Class.new(FaviconFactory::Cli) do
      define_method(:touch!) do |_, params|
        raise(params.background) if params.background != "blue"
      end
    end

    with_svg do |_dir, path|
      status = testable_call.new([path, "--background", "blue"], StringIO.new).call

      assert_equal 0, status
    end

    with_svg do |_dir, path|
      status = testable_call.new([path, "--background=blue"], StringIO.new).call

      assert_equal 0, status
    end

    with_svg do |_dir, path|
      status = testable_call.new([path, "-b", "blue"], StringIO.new).call

      assert_equal 0, status
    end
  end

  private

  def with_svg
    Tempfile.create(["one", ".svg"]) do |file|
      file.write("<svg></svg>")
      file.rewind
      path = file.path
      dir = File.dirname(path)
      TARGETS.each { FileUtils.rm_f(File.join(dir, _1)) }
      yield(dir, path)
    end
  end
end
