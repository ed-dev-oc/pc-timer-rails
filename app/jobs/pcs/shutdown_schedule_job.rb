class Pcs::ShutdownScheduleJob < ApplicationJob
  queue_as :default

  def perform(pc_id)
    pc = Pc.find(pc_id)

    return if pc.active_session.present? || pc.disabled_kiosk?

    pc.shutdown!
  end
end
