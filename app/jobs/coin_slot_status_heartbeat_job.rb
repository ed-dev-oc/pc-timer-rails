class CoinSlotStatusHeartbeatJob < ApplicationJob
  queue_as :background

  def perform
    CoinSlot.where(status: :active)
            .where("last_seen_at < ?", Setting.integer('coin_slot_offline_threshold').minutes.ago)
            .update_all(status: "offline")
  end
end
