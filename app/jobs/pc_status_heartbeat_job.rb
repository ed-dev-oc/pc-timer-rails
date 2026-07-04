class PcStatusHeartbeatJob < ApplicationJob
  queue_as :default

  def perform
    Pc.where("last_seen_at < ?", Setting.integer("pc_offline_threshold").minutes.ago).where.not(status: [ :disabled_kiosk, :uninstalled ])
      .update_all(status: "offline")
  end
end
