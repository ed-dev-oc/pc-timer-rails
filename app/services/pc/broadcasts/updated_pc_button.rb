# frozen_string_literal: true

class Pc
  module Broadcasts
    # Service object that replicates the former `PcSession#boradcast_updated_pc_button`.
    class UpdatedPcButton
      # @param pc_session [PcSession] the session that triggered the broadcast
      def self.call(pc_session)
        pc = pc_session.pc.reload

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
