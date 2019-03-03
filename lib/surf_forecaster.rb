# frozen_string_literal: true

require 'httparty'

# Helper class that queries Windguru Public API
# for information about the Surf spots
class SurfForecaster
  @base_uri = 'https://www.windguru.cz'
  @http_headers = { headers: { "Referer": 'https://www.windguru.cz' } }

  class << self
    def search_spot(search_query, top = 5)
      options = build_search_spot_query(search_query)
      options.merge!(@http_headers)

      response = HTTParty.get("#{@base_uri}/int/iapi.php", options)
      return unless response.code

      response['suggestions'].take(top)
    rescue StandardError => e
      puts e.full_message
      { error: 'Error processing the request' }
    end

    def get_spot_info(spot_id)
      options = build_info_query(spot_id)
      options.merge!(@http_headers)

      response = HTTParty.get("#{@base_uri}/int/iapi.php", options)
      return unless response.code

      process_info_response(spot_id,response)
    rescue StandardError => e
      puts e.full_message
      { error: 'Error processing the request' }
    end

    def get_spot_forecast(spot_id, model, initstr)
      options = build_forecast_query(spot_id, model, initstr)
      options.merge!(@http_headers)

      response = HTTParty.get("#{@base_uri}/int/iapi.php", options)
      return unless response.code

      process_forecast_response(spot_id, model, response)
    rescue StandardError => e
      puts e.full_message
      { error: 'Error processing the request' }
    end

    private

    def build_search_spot_query(search_query)
      {
        query: {
          query: search_query,
          q: 'autocomplete_ss'
        }
      }
    end

    def build_info_query(spot_id)
      {
        query: {
          id_spot: spot_id,
          q: 'forecast_spot'
        }
      }
    end

    def build_forecast_query(spot_id, model_id, initstr)
      {
        query: {
          id_spot: spot_id,
          id_model: model_id,
          q: 'forecast',
          initstr: initstr
        }
      }
    end

    def process_info_response(spot_id, response)
      spot_model_fcst = response['fcst'].find { |obj| obj['id_model'] == 25 }

      {
        spot_id: spot_id,
        name: response.dig('spots', spot_id.to_s, 'spotname'),
        country: response.dig('spots', spot_id.to_s, 'country'),
        lat: response.dig('spots', spot_id.to_s, 'lat'),
        lon: response.dig('spots', spot_id.to_s, 'lon'),
        sunrise: response.dig('spots', spot_id.to_s, 'sunrise'),
        sunset: response.dig('spots', spot_id.to_s, 'sunset'),
        initstr: spot_model_fcst ? spot_model_fcst['initstr'] : ''
      }
    end

    def process_forecast_response(spot_id, model_id, response)
      data_vars = response.dig('fcst', 'vars')

      {
        spot_id: spot_id,
        model_id: model_id,
        model_name: response.dig('wgmodel', 'model_name'),
        updated_at: response.dig('fcst', 'update_last'),
        data: data_vars.map do |var|
          [var, response.dig('fcst', var)]
        end.to_h
      }
    end
  end
end
