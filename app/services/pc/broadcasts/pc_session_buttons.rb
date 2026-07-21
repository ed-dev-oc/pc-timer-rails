# frozen_string_literal: true

class Pc
  module Broadcasts
    # Service object for broadcasting the PC session buttons UI.
    # Mirrors the original `Pc#broadcast_pc_session_buttons` method.
    class PcSessionButtons
      # @param pc [Pc] the PC record to broadcast
      def self.call(pc)
        pc.broadcast_replace_to(
          "coin_slot_session_button",
          target: ActionView::RecordIdentifier.dom_id(pc, :insert_coin_card),
          partial: "winform/pcs/button",
          locals: { pc: pc }
        )
      end
    end
  end
end
