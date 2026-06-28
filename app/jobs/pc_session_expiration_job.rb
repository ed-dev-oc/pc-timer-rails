class PcSessionExpirationJob < ApplicationJob
  queue_as :default

  def perform(pc_session_id)
    pc_session = PcSession.find_by(id: pc_session_id)
    pc = pc_session.pc

    if Time.current >= pc_session.expires_at && pc_session.present? && pc_session.active?
      pc_session.update(
        status: :ended,
        total_minutes_used: pc_session.total_minutes_purchased
      )

      pc.mark_online_and_lock_pc!
    end
  end
end
