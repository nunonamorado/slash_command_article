require "httparty"

class SurfForecaster
  @@base_uri = "https://www.windguru.cz"
  @@http_headers = { headers: { "Referer": "https://www.windguru.cz" } }

  def self.search_spot(search_query, top = 5)
    options = {
      query: {
        query: search_query,
        q: "autocomplete_ss"
      }
    }

    response = HTTParty.get("#{@@base_uri}/int/iapi.php", options.merge(@@http_headers))
    response["suggestions"].take(top)
  rescue StandardError => e
    puts e.full_message
    { error: "Error processing the request" }
  end

  def self.get_spot_info(spot_id)
    options = {
      query: {
        id_spot: spot_id,
        q: "forecast_spot"
      }
    }
    response = HTTParty.get("#{@@base_uri}/int/iapi.php", options.merge(@@http_headers))
    spot_model_fcst = response["fcst"].find { |obj| obj["id_model"] == 25 }

    info = {
      spot_id: spot_id,
      name: response.dig("spots", spot_id.to_s, "spotname"),
      country: response.dig("spots", spot_id.to_s, "country"),
      lat: response.dig("spots", spot_id.to_s, "lat"),
      lon: response.dig("spots", spot_id.to_s, "lon"),
      sunrise: response.dig("spots", spot_id.to_s, "sunrise"),
      sunset: response.dig("spots", spot_id.to_s, "sunset"),
      initstr: spot_model_fcst ? spot_model_fcst["initstr"] : "",
    }

    info[:loc_map] = "https://surforecaster-mapsproxy.now.sh/staticmap/?lat=#{info[:lat]}&lon=#{info[:lon]}"
    info
  rescue StandardError => e
    puts e.full_message
    { error: "Error processing the request" }
  end

  def self.get_spot_forecast(spot_id, initstr)
    options = {
      query: {
        id_spot: spot_id,
        # Forecast based on NWW3 wave forecast model with resolution of about 50 km.
        # Updates 4 times per day and offers forecast for 180 hours.
        # Data source: NOAA (American weather service)
        id_model: 25,
        q: "forecast",
        initstr: initstr
      }
    }
    response = HTTParty.get("#{@@base_uri}/int/iapi.php", options.merge(@@http_headers))

    data_vars = response.dig("fcst", "vars")


    return {
      spot_id: spot_id,
      model_id: 25,
      model_name: response.dig("wgmodel", "model_name"),
      updated_at: response.dig("fcst", "update_last"),
      data: data_vars.map do |var|
        [var, response.dig("fcst", var)]
      end.to_h
    }
  rescue StandardError => e
    puts e.full_message
    { error: "Error processing the request" }
  end
end


