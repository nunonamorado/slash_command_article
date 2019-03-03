# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/slack'
require 'rack/reverse_proxy'

require_relative './lib/surf_forecaster'

MAPBOX_URL = 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/static'
MAPBOX_TOKEN = ENV['MAPBOX_API_TOKEN']

# Slack Application
class App < Sinatra::Base
  register Sinatra::Slack

  configure :production, :development do
    enable :logging

    before { logger.info "Received: #{params}" }
  end

  use Rack::ReverseProxy do
    destination = "#{MAPBOX_URL}/$1,13,0,0/512x288@2x" \
                  "?access_token=#{MAPBOX_TOKEN}"
    reverse_proxy %r{^/staticmap/?(.*)$}, destination
  end

  set :slack_secret, ENV['SLACK_SIGNING_SECRET']
  commands_endpoint '/slack/commands'
  actions_endpoint '/slack/actions'

  command '/surf *granularity :spot_name' do |granularity, spot_name|
    process_command granularity, spot_name
  end

  action 'spot_info_:granularity' do |granularity, spot_id|
    fetch_forecast_and_respond granularity, spot_id
  end

  private

  def process_command(granularity, spot_name)
    spots = SurfForecaster.search_spot(spot_name)

    if spots.size == 1
      spot_id = spots.first['data']
      return fetch_forecast_and_respond(granularity, spot_id)
    end

    slack_response "spot_info_#{granularity}" do |r|
      r.text = "Several spots found (#{spots.size})"

      r.attachment do |a|
        a.fallback = 'No surf spots found!'
        a.title = 'Please choose one from the following'

        spots.each do |spot|
          a.action_button 'surf_spot', spot['value'], spot['data']
        end
      end
    end
  end

  def build_forecast_message(info)
    location_map = "https://#{request.host}/staticmap/" \
                  "#{info[:lon]},#{info[:lat]}"

    slack_response 'spot_info' do |r|
      r.mrkdwn = true
      r.text = format_forecast_info(info)
      r.attachment do |a|
        a.title = 'Spot location'
        a.image_url = location_map
      end
    end
  end

  def fetch_forecast_and_respond(_granularity, spot_id)
    info = SurfForecaster.get_spot_info(spot_id)
    forecast = SurfForecaster.get_spot_forecast(spot_id, info[:initstr])
    info.merge!(forecast) if forecast

    build_forecast_message(info)
  end

  def format_forecast_info(info)
    data = info[:data]
    "Here is the information for _*#{info[:name]}*_ \n\n" \
    "*Wave (m)*:           _#{data['HTSGW'].first}_\n" \
    "*Wave Period (s)*:    _#{data['PERPW'].first}_\n" \
    "*Wave Direction *:    _#{convert_direction(data['DIRPW'].first)}_\n\n" \
  end

  def convert_direction(dir)
    case dir
    when 0..45 then 'N'
    when 46..90 then 'NE'
    when 91..135 then 'E'
    when 136..180 then 'SE'
    when 181..225 then 'S'
    when 226..270 then 'SW'
    when 271..315 then 'W'
    else 'NW'
    end
  end
end
