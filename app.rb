# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/slack'
require 'rack/reverse_proxy'

require_relative './surf_forecaster/helpers'

MAPBOX_URL = 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/static'
MAPBOX_TOKEN = ENV.fetch('MAPBOX_API_TOKEN')
SLACK_SIGNING_SECRET = ENV.fetch('SLACK_SIGNING_SECRET')

# Slack Application
class App < Sinatra::Base
  register Sinatra::Slack
  helpers SurfForecaster::Helpers

  configure :production, :development do
    enable :logging

    before { logger.info "Received: #{params}" }
  end

  use Rack::ReverseProxy do
    destination = "#{MAPBOX_URL}/$1,13,0,0/512x288@2x" \
                  "?access_token=#{MAPBOX_TOKEN}"
    reverse_proxy %r{^/staticmap/?(.*)$}, destination
  end

  set :slack_secret, SLACK_SIGNING_SECRET
  commands_endpoint '/slack/commands',
                    quick_reply: ':male_genie: Sim Sim Salabim :surfer:'
  actions_endpoint '/slack/actions'

  command '/surf *granularity :spot_name' do |granularity, spot_name|
    process_command granularity, spot_name
  end

  action 'spot_info_:granularity' do |granularity, spot_id|
    fetch_forecast_and_respond granularity, spot_id
  end
end
