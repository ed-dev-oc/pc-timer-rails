module CoinSlots
  class StatusHeartbeatJob < ApplicationJob
    queue_as :background

    def perform
      CoinSlot.where(status: :online)
        .where("last_seen_at < ?", Setting.integer("coin_slot_offline_threshold").minutes.ago)
        .find_in_batches(batch_size: 100) do |batch|
        batch.each do |coin_slot|
          coin_slot.update(status: "offline")
          CoinSlots::Broadcasts::BadgeStatus.call(coin_slot)
        end
      end
    end
  end
end
