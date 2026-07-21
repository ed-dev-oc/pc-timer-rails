class PcSessionExpirationJob < ApplicationJob
  queue_as :default

  def perform(pc_session_id)
    pc_session = PcSession.find_by(id: pc_session_id)
    return unless pc_session

    pc = pc_session.pc

    if Time.current >= pc_session.expires_at && pc_session.present? && pc_session.active?
      total_minutes_used = (Time.current - pc_session.started_at).ceil / 60

      pc_session.update(
        status: :ended,
        total_minutes_used: total_minutes_used
      )

      pc.mark_online_and_lock_pc!
      Pc::Broadcasts::BadgeStatus.call(pc)
    end
  end
end
