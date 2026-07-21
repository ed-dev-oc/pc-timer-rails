# frozen_string_literal: true

# Service object responsible for broadcasting the PC status badge.
# It mirrors the original `Pc#broadcast_badge_status` implementation.
class Pc
  module Broadcasts
    class BadgeStatus
      # @param pc [Pc] the PC record to broadcast
      def self.call(pc)
        pc.broadcast_replace_to(
          "badge_status",
          target: ActionView::RecordIdentifier.dom_id(pc, :badge_status),
          partial: "shared/status_badge",
          locals: { object: pc }
        )
      end
    end
  end
end
