class PcStatusHeartbeatJob < ApplicationJob
  queue_as :default

  def perform
    Pc.where("last_seen_at < ?", 2.minutes.ago)
      .update_all(status: "offline")
  end
end
