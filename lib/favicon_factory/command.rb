require "tty/option"

module FaviconFactory
  class Command
    include TTY::Option

    usage do
      program "favicon_factory"
      no_command

      desc <<~DESC
        `favicon_factory` generates from an SVG the minimal set of icons needed by modern browsers.

        The source SVG is ideal for [modern browsers](https://caniuse.com/link-icon-svg). And it may contain a `<style>` tag with `@media (prefers-color-scheme: dark)` to support light/dark themes, which is ignored when generating favicons.

        Icons will be generated in the same folder as the source SVG unless already existing:

        - `favicon.ico` (32x32) for legacy browsers; serve it from `/favicon.ico` because tools, like RSS readers, just look there.
        - `apple-touch-icon.png` (180x180) for Apple devices when adding a webpage to the home screen; a background and a padding around the icon is applied to make it look pretty.
        - `manifest.webmanifest` that includes `icon-192.png`, `icon-512.png`, and `icon-mask.png` for Android devices; the first for display on the home screen, the second for different Android launchers, and the last for the splash screen while the PWA is loading.
      DESC

      example "favicon_factory path/to/favicon.svg"
      example "favicon_factory --background red path/to/favicon.svg"
      example "favicon_factory --background #000000 path/to/favicon.svg"
    end

    argument :favicon_svg do
      name "favicon_svg"
      desc "Path to the favicon.svg"
    end

    option :background do
      short "-b"
      long "--background string"
      default "#ffffff"
      desc "Background hex color for apple-touch-icon.png"
    end

    flag :help do
      short "-h"
      long "--help"
      desc "Print usage"
    end
  end
end
