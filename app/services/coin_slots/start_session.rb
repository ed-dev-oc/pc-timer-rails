class CoinSlots::StartSession
  def self.call(pc, coin_slot)
    new(pc, coin_slot).call
  end

  def initialize(pc, coin_slot)
    @pc = pc
    @coin_slot = coin_slot
  end

  def call
    coin_slot_session = nil

    ActiveRecord::Base.transaction do
      coin_slot_session = @coin_slot.start_session!(@pc)
      coin_slot_session.schedule_expiration

      @coin_slot.queue_esp_command!(command: :enable)
    end

    @coin_slot.reload
    @coin_slot.broadcast_badge!
    @coin_slot.broadcast_session!

    Result.success(coin_slot_session)
  rescue ActiveRecord::RecordInvalid => e
    Result.failure(e.message)
  end
end
