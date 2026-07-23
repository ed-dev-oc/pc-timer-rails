class CoinSlot
  class CreateSession
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
        set_coin_slot_status_to_active_session!
        schedule_expiration
        queue_esp_enable_command!
      end

      @coin_slot.reload
      CoinSlot::Broadcasts::BadgeStatus.call(@coin_slot)
      CoinSlot::Broadcasts::Session.call(@coin_slot)

      Result.success(@coin_slot_session)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.message)
    end

    private

    def create_coin_slot_session!
      @coin_slot_session = CoinSlotSession.create!(pc: @pc, coin_slot: @coin_slot)
    end

    def set_coin_slot_status_to_active_session!
      @coin_slot.active_session! if @coin_slot.present?
    end

    def schedule_expiration
      CoinSlotSessionTimerJob.set(wait_until: @coin_slot_session.ended_at).perform_later(@coin_slot_session.id)
    end

    def queue_esp_enable_command!
      @coin_slot.esp_command_logs.create!(command: :enable, status: :pending, sent_at: Time.current)
    end
  end
end
