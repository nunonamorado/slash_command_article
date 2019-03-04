FROM ruby:2.5.3-alpine3.8

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

COPY . .

EXPOSE 3000

ENV SLACK_SIGNING_SECRET $SLACK_SIGNING_SECRET
ENV MAPBOX_API_TOKEN $MAPBOX_API_TOKEN

CMD ["bundle", "exec", "rackup"]
