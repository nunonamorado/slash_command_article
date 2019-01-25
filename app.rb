require "sinatra/base"
require "sinatra/json"
require_relative "lib/surf_forecaster"

require "cksh_commander"
CKSHCommander.configure do |c|
  c.commands_path = File.expand_path("../commands", __FILE__)
end

class App < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

  set :bind, "0.0.0.0"

  get "/search_spot" do
    result = SurfForecaster.search_spot(params['name']) unless params['name'].empty?
    json result
  end

  get "/spot_forecast" do

    unless params['id'].empty?
      spot_info = SurfForecaster.get_spot_info(params['id'])
      result = SurfForecaster.get_spot_forecast(params['id'], spot_info[:initstr])
      result = result.merge(spot_info)
    end

    json result
  end

  post "/forecaster" do
    content_type "application/x-www-form-urlencoded"

    # in case someone already read it
    request.body.rewind
    # just to be sure that Slack payload is correctly decoded
    decoded = URI.decode(request.body.read)
    data = URI.decode_www_form(decoded).to_h

    logger.info "received: #{data}"

    command = data["command"][1..-1]
    response = CKSHCommander::Runner.run(command, data)
    json response.serialize
  end

  post "/slack/actions" do
    content_type :json

    payload = JSON.parse params["payload"]
    logger.info "received: #{payload}"

    if payload["type"] == "interactive_message" && payload["callback_id"] == "forecast"
      action = payload["actions"].first

      spot_id = action["value"]

      spot_info = SurfForecaster.get_spot_info(spot_id)
      result = SurfForecaster.get_spot_forecast(spot_id, spot_info[:initstr])

      response = {
        attachments: [
          {
            title: spot_info[:name],
            text: "Optional text that appears within the attachment",
            color: "#3AA3E3",
            image_url: spot_info[:loc_map]
          }
        ]
      }
    end

    json response
  end
end
