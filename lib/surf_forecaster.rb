require "httparty"

class SurfForecaster
  @@base_uri = "https://www.windguru.cz"
  @@http_headers = { headers: { "Referer": "https://www.windguru.cz" } }

  def self.search_spot(search_query, top = 5)
    options = {
      query: {
        query: search_query,
        q: "autocomplete_ss",
        type_info: "true",
        all: "0",
        latlon: "1",
        country: "1",
        favourite: "1",
        custom: "1",
        stations: "1",
        spots: "1",
        priority_sort: "1",
        _mha: "a5134e97"
      }
    }

    response = HTTParty.get("#{@@base_uri}/int/iapi.php", options.merge(@@http_headers))
    response["suggestions"].take(top)
  rescue StandardError => e
    puts e.message
    { error: "Error processing the request" }
  end

  def self.get_spot_forecast(spot_id)
    options = {
      query: {
        id_spot: spot_id,
        q: "forecast_spot",
        _mha: "0e82973a"
      }
    }

    response = HTTParty.get("#{@@base_uri}/int/iapi.php", options.merge(@@http_headers))
    response["tabs"]
  rescue StandardError => e
    puts e.message
    { error: "Error processing the request" }
  end
end
