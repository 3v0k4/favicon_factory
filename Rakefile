# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[test:unit test:e2e rubocop]

namespace :test do
  task :unit do
    system("X=/e2e/ bin/rake test")
  end

  task :e2e do
    require "open3"

    unpath_vips = "unpath libvips unpath libvips-tools unpath vips"
    statuses = [
      ["bin/rake test N=/e2e__with_deps/"],
      ["#{unpath_vips} bin/rake test N=/e2e__with_deps/"],
      ["apt-get remove -y --purge *imagemagick* inkscape libvips libvips-tools && bin/rake test N=/e2e__without_deps/"],
      ["#{unpath_vips} bin/rake test N=/e2e__with_deps/", "--build-arg IMAGE_MAGICK_VERSION=6.9.13-11"]
    ].map do |command, build_args|
      command = "docker run $(docker build -q #{build_args} .) bash -c '#{command}'"
      stdout, stderr, status = Open3.capture3(command)
      puts "=" * command.size
      puts command
      puts "=" * command.size
      puts stderr
      puts stdout
      status
    end

    raise "Some tests failed" if statuses.map(&:exitstatus).max.positive?
  end
end
