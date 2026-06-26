class CreateCoinSlotSession
  def self.call(pc, coin_slot)
    new(pc, coin_slot).call
  end

  def initialize(pc, coin_slot)
    @pc = pc
    @coin_slot = coin_slot
    @coin_slot_session = nil
  end

  def call
    ActiveRecord::Base.transaction do
      create_coin_slot_session!
      schedule_expiration
      queue_esp_enable_command!
    end

    @coin_slot.reload

    Result.success(@coin_slot_session)
  rescue ActiveRecord::RecordInvalid => e
    Result.failure(e.message)
  end

  private

    def create_coin_slot_session!
      @coin_slot_session = CoinSlotSession.create!(
        pc: @pc,
        coin_slot: @coin_slot
      )
    end

    def schedule_expiration
      CoinSlotSessionTimerJob.set(wait_until: @coin_slot_session.ended_at).perform_later(@coin_slot_session.id)
    end

    def queue_esp_enable_command!
      @coin_slot.esp_command_logs.create!(
        command: :enable,
        status: :pending
      )
    end
end
