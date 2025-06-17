# frozen_string_literal: true

require_relative "lib/favicon_factory/version"

Gem::Specification.new do |spec|
  spec.name = "favicon_factory"
  spec.version = FaviconFactory::VERSION
  spec.authors = ["3v0k4"]
  spec.email = ["riccardo.odone@gmail.com"]

  spec.summary = "Generate favicons from an SVG"
  spec.description = "FaviconFactory generates from an SVG the minimal set of icons needed by modern browsers."
  spec.homepage = "https://github.com/3v0k4/favicon_factory"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/3v0k4/favicon_factory"
  spec.metadata["changelog_uri"] = "https://github.com/3v0k4/favicon_factory/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("lib/**/*") + Dir.glob("exe/*")
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "mini_magick", "~> 5.2"
  spec.add_dependency "ruby-vips", "~> 2.2"
  spec.add_dependency "tty-option", "~> 0.3.0"
  spec.add_dependency "tty-which", "~> 0.5.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
