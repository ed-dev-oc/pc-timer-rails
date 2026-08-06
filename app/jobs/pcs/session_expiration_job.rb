module Pcs
  class SessionExpirationJob < ApplicationJob
    queue_as :default

    def perform(pc_session_id)
      pc_session = PcSession.find_by(id: pc_session_id)
      return unless pc_session

      pc = pc_session.pc

      if Time.current >= pc_session.expires_at && pc_session.present? && pc_session.active?
        pc.stop_session!(pc_session)

        Pcs::Broadcasts::BadgeStatus.call(pc)
        PcSessions::BroadcastService.call(pc)
      end
    end
  end
end
