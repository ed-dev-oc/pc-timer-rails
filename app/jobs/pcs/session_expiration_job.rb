module Pcs
  class SessionExpirationJob < ApplicationJob
    queue_as :default

    def perform(pc_session_id)
      pc_session = PcSession.find_by(id: pc_session_id)
      return unless pc_session
      return if pc_session.ended?

      pc = pc_session.pc

      if pc_session.expired?
        pc.stop_session!(pc_session)

        Pcs::Broadcasts::BadgeStatus.call(pc)
        PcSessions::BroadcastService.call(pc)
      end
    end
  end
end
