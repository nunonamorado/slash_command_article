FROM ruby:2.5.3-stretch

RUN gem install bundler
RUN gem install eventmachine

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

COPY . .

ARG SLACK_SIGNING_SECRET
ARG MAPBOX_API_TOKEN

CMD bundle exec rackup --host 0.0.0.0 -p $PORT