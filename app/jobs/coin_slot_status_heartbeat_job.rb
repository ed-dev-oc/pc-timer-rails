class CoinSlotStatusHeartbeatJob < ApplicationJob
  queue_as :background

  def perform
    CoinSlot.where(status: :active)
            .where("last_seen_at < ?", 2.minutes.ago)
            .update_all(status: "offline")
  end
end
