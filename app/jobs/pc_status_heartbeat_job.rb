class PcStatusHeartbeatJob < ApplicationJob
  queue_as :default

  def perform
    Pc.where(status: :online)
      .where("last_seen_at < ?", Setting.integer("pc_offline_threshold").minutes.ago)
      .find_in_batches(batch_size: 100) do |batch|
      batch.each do |pc|
        pc.offline!
        Pcs::Broadcasts::BadgeStatus.call(pc)
      end
    end
  end
end
