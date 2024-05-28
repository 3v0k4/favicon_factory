# frozen_string_literal: true

require "test_helper"
require "open3"

class TestE2e < Minitest::Test
  def test_e2e__without_deps__with_existing_svg__it_succeeds
    with_svg do |_dir, path|
      _, stderr, status = Open3.capture3("bundle exec exe/favicon_factory #{path}")

      assert_equal 1, status.exitstatus
      assert_match Regexp.new("Error: Neither vips or imagemagick found, install one"), stderr
    end
  end

  def test_e2e__with_deps__with_existing_svg__it_succeeds
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
end
