require "cksh_commander"
require_relative "../../lib/surf_forecaster"

module Surf
  class Command < CKSHCommander::Command
    set token: ENV["SLACK_VERIFICATION_TOKEN"]

    desc "today [spot_name]", "Get today's surf forecast for [spot_name]"
    def today(spot_name)
      spots = SurfForecaster.search_spot(spot_name, 5)

      return set_response_text("Subcommand: today; Text: #{spot_name}") unless spots.size > 1

      spots_action = []
      spots.each do |spot|
        spots_action << {
          name: "surf_spot",
          text: spot["value"],
          type: "button",
          value: spot["data"]
        }
      end

      set_response_text("Several spots found (#{spots.size})")
      add_response_attachment({
        text: "Please choose one from the following",
        fallback: "No surf spots found!",
        callback_id: "forecast",
        attachment_type: "default",
        color: "#3AA3E3",
        actions: spots_action
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
  end
end
