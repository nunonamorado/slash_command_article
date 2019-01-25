require "cksh_commander"
require_relative "../../lib/surf_forecaster"

module Surf
  class Command < CKSHCommander::Command
    set token: ENV["SLACK_VERIFICATION_TOKEN"]

    desc "today [spot_name]", "Get today's surf forecast for [spot_name]"
    def today(spot_name)
      spots = SurfForecaster.search_spot(spot_name, 5)

      unless spots.size > 1
        spot_id = spots.first["data"]
        spot_info = SurfForecaster.get_spot_info(spot_id)
        result = SurfForecaster.get_spot_forecast(spot_id, spot_info[:initstr])

        return add_response_attachment({
          title: spot_info[:name],
          text: "Optional text that appears within the attachment",
          color: "#3AA3E3",
          image_url: spot_info[:loc_map]
        })
      end

      spots_action = []
      spots.each do |spot|
        spots_action << {
          name: "surf_spot",
          text: spot["value"],
          type: "button",
          value: spot["data"]
        }
      end

      add_response_attachment({
        title: "Several spots found (#{spots.size})",
        text: "Please choose one from the following",
        fallback: "No surf spots found!",
        callback_id: "forecast",
        attachment_type: "default",
        color: "#3AA3E3",
        actions: spots_action,
      })
    end

    desc "tomorrow [spot_name]", "Get tomorrow's surf forecast for [spot_name]"
    def tomorrow(spot_name)
      set_response_text("Subcommand: tomorrow; Text: #{spot_name}")
    end

    desc "week [spot_name]", "Get week's surf forecast for [spot_name]"
    def week(spot_name)
      set_response_text("Subcommand: week; Text: #{spot_name}")
    end

    desc "[TEXT]", "Root command description."
    def ___(text)
      set_response_text("Root command; Text: #{text}")
    end


    private

    def fetch_spot_by_name(name)

    end

    def fetch_forecast_data(spot_id)

    end
  end
end
