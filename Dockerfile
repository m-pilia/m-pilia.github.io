FROM ruby:4.0.1-slim

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

# hadolint ignore=DL3008
RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /srv/jekyll
COPY Gemfile* ./

RUN gem install bundler:4.0.6 \
&&  bundle install

EXPOSE 4000

CMD [ "/usr/local/bundle/bin/bundle", "exec", "/usr/local/bundle/bin/jekyll", "serve", "--port", "4000", "--host", "0.0.0.0" ]

STOPSIGNAL 2
