FROM ruby:2.5.3-alpine

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 5000

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "5000"]