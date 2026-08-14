class Pcs::ShutdownScheduleJob < ApplicationJob
  queue_as :default

  def perform(pc_id)
    pc = Pc.find(pc_id)

    return if pc.active_session.present? || Pc::IMMUTABLE_STATUSES.include?(pc.status.to_sym)

    pc.shutdown!
  end
end
