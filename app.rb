require "sinatra/base"
require "sinatra/slack"
require 'rack/reverse_proxy'

require_relative "./lib/surf_forecaster"

MAPBOX_URL = 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/static'
MAPBOX_TOKEN = ENV['MAPBOX_API_TOKEN']

class App < Sinatra::Base
  register Sinatra::Slack
  
  configure :production, :development do
    enable :logging
    
    before { logger.info "Received: #{params}"}
  end

  use Rack::ReverseProxy do    
    reverse_proxy /^\/staticmap\/?(.*)$/, "#{MAPBOX_URL}/$1,13,0,0/512x288@2x?access_token=#{MAPBOX_TOKEN}"
  end

  verify_slack_request ENV["SLACK_SIGNING_SECRET"]
  commands_endpoint "/slack/commands", quick_reply: ":surfer: Fetching..."
  actions_endpoint "/slack/actions"

  command "/surf *sub_command :spot_name" do |sub_command, spot_name|
    process_command sub_command, spot_name
  end

  action "spot_info" do |spot_id|
    fetch_forecast_and_respond spot_id
  end

  private

  def process_command(granularity, spot_name)
    spots = SurfForecaster.search_spot(spot_name)

    if spots.size == 1
      spot_id = spots.first["data"]
      return fetch_forecast_and_respond(spot_id)
    end

    slack_response "spot_info" do |r|
      r.text = "Several spots found (#{spots.size})"

      r.attachment do |a|
        a.fallback = "No surf spots found!"
        a.title = "Please choose one from the following"

        spots.each do |spot|
          a.action_button "surf_spot", spot["value"], spot["data"]
        end
      end
    end
  end

  def build_forecast_message(forecast_info)
    slack_response "spot_info" do |r|
      r.text = "Here is the spot information:"
      r.attachment do |a|
        a.title = "Spot location: #{forecast_info[:name]}"
        a.image_url = forecast_info[:loc_map]
      end
    end
  end

  def fetch_forecast_and_respond(spot_id)
    spot_info = SurfForecaster.get_spot_info(spot_id)
    forecast_info = SurfForecaster.get_spot_forecast(spot_id, spot_info[:initstr])
    forecast_info.merge!(spot_info)
    build_forecast_message(forecast_info)
  end
end
