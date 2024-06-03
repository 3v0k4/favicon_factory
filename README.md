# FaviconFactory

<div align="center">
  <img width="200" width="200" src=".github/images/favicon_factory.svg" />
</div>

`favicon_factory` generates from an SVG the minimal set of icons needed by modern browsers.

The source SVG is ideal for [modern browsers](https://caniuse.com/link-icon-svg). And it may contain a `<style>` tag with `@media (prefers-color-scheme: dark)` to support light/dark themes, which is ignored when generating favicons.

Icons will be generated in the same folder as the source SVG unless already existing:

- `favicon.ico` (32x32) for legacy browsers; serve it from `/favicon.ico` because tools, like RSS readers, just look there.
- `apple-touch-icon.png` (180x180) for Apple devices when adding a webpage to the home screen; a background and a padding around the icon is applied to make it look pretty.
- `manifest.webmanifest` that includes `icon-192.png` and `icon-512.png` for Android devices; the former for display on the home screen, and the latter for the splash screen while the PWA is loading.

## Users

<p>
  <a href="https://rictionary.odone.io">
    <img width="100" width="100" hspace="10" src=".github/images/rictionary.svg" />
  </a>

  <a href="https://typescript.tips">
    <img width="100" width="100" hspace="10" src=".github/images/typescript-tips.svg" />
  </a>
</p>

## Installation

Vips or ImageMagick+Inkscape are required. If both are present, FaviconFactory defaults to Vips.

Vips:

```bash
brew install vips
```

```bash
sudo apt-get install libvips
sudo apt-get install libvips-tools
```

ImageMagick and Inkscape:

```bash
brew install imagemagick
brew install inkscape
```

```bash
sudo apt-get install imagemagick # for v7 consider https://github.com/SoftCreatR/imei/
sudo apt-get install inkscape
```

Add `favicon_factory` to the Gemfile:

```bash
bundle add favicon_factory
```

Or just install the executable:

```bash
gem install favicon_factory
```

## Usage

To generate the favicons (see `samples/` for an example set):

```bash
favicon_factory samples/favicon.svg

# Info: Generating samples/favicon.ico
# Info: Generating samples/icon-192.png
# Info: Generating samples/icon-512.png
# Info: Generating samples/apple-touch-icon.png
# Info: Generating samples/manifest.webmanifest
# Info: Add the following to the `<head>`
#   <!-- favicons generated with the favicon_factory gem -->
#   <link rel="icon" href="/favicon.svg" type="image/svg+xml">
#   <link rel="icon" href="/favicon.ico" sizes="32x32">
#   <link rel="apple-touch-icon" href="/apple-touch-icon.png">
#   <link rel="manifest" href="/manifest.webmanifest">
```

To show all the options:

```bash
favicon_factory --help
```

## Development

After checking out the repo, run `bin/setup` to install the dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/3v0k4/favicon_factory).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Credits

This gem was inspired by an article on [Evil Martians](https://evilmartians.com/chronicles/how-to-favicon-in-2021-six-files-that-fit-most-needs).
