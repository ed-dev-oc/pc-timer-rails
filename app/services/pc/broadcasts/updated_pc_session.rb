# frozen_string_literal: true

class Pc
  module Broadcasts
    # Service object that replicates the former `PcSession#broadcast_updated_pc_session`.
    class UpdatedPcSession
      # @param pc_session [PcSession] the session that triggered the broadcast
      def self.call(pc_session)
        pc = pc_session.pc.reload
        pc_session_record = pc.active_pc_session&.reload

        pc.broadcast_replace_to(
          "pc_card",
          target: ActionView::RecordIdentifier.dom_id(pc, :pc_session),
          partial: "winform/pc_sessions/pc_session",
          locals: { pc: pc, pc_session: pc_session_record }
        )
      end
    end
  end
end
