require "sinatra/base"

class App < Sinatra::Base
  set :bind, "0.0.0.0"

  get "/" do
    "<p>hello world</p> #{Time.now}"
  end
end
