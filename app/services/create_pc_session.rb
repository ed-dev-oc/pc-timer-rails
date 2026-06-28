class CreatePcSession
  def self.call(pc)
    new(pc).call
  end

  def initialize(pc)
    @pc = pc
    @coin_transactions = pc.coin_transactions.unused
    @coin_slot_session = pc.active_coin_slot_session
    @pc_session = nil
  end

  def call
    ActiveRecord::Base.transaction do
      create_pc_session!
      deactivate_coin_slot_session!
      schedule_expiration
      active_pc_session!
      mark_transactions_used!
    end

    @pc.reload

    Result.success(@pc_session)
  rescue ActiveRecord::RecordInvalid => e
    Result.failure(e.message)
  end

  private

    def create_pc_session!
      total_minutes = @coin_transactions.sum(:minutes_granted)

      @pc_session = PcSession.create!(
        pc: @pc,
        total_minutes_purchased: total_minutes,
        started_at: Time.current,
        expires_at: Time.current + total_minutes.minutes
      )
    end

    def schedule_expiration
      PcSessionExpirationJob.set(wait_until: @pc_session.expires_at).perform_later(@pc_session.id)
    end

    def deactivate_coin_slot_session!
      if @coin_slot_session.present? && @coin_slot_session.active?
        @coin_slot_session.mark_inactive_and_disable_esp!
      end
    end

    def active_pc_session!
      @pc.mark_active_session_and_unlock_pc!
    end

    def mark_transactions_used!
      @coin_transactions.each(&:used!)
    end
end
