FROM ruby:3.3

ARG IMAGE_MAGICK_VERSION=7.1.1-33

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN apt remove --purge -y "*imagemagick*" && \
    apt autoremove --purge -y
RUN apt-get update && apt-get install -y \
    checkinstall && \
    rm -rf /var/lib/apt/lists/*
RUN t=$(mktemp) && \
    wget 'https://dist.1-2.dev/imei.sh' -qO "$t" && \
    bash "$t" --checkinstall --imagemagick-version=$IMAGE_MAGICK_VERSION && \
    rm "$t"

RUN apt-get update && apt-get install -y \
    inkscape \
    libvips \
    libvips-tools && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY lib/favicon_factory/version.rb ./lib/favicon_factory/version.rb
COPY favicon_factory.gemspec Gemfile Gemfile.lock .
RUN bundle install

COPY . .

CMD ["bin/console"]
