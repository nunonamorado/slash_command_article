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
    result = SurfForecaster.get_spot_forecast(params['id']) unless params['id'].empty?
    json result
  end

  post "/forecaster" do
    content_type "application/x-www-form-urlencoded"

    request.body.rewind  # in case someone already read it
    decoded = URI.decode(request.body.read)
    data = URI.decode_www_form(decoded).to_h

    command = data["command"][1..-1]
    response = CKSHCommander::Runner.run(command, data)
    json response.serialize
  end
end
