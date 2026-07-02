class UpdatePcSession
  def self.call(pc, pc_session)
    new(pc, pc_session).call
  end

  def initialize(pc, pc_session)
    @pc = pc
    @pc_session = pc_session
    @coin_transactions = pc.coin_transactions.unused
    @coin_slot_session = pc.active_coin_slot_session
  end

  def call
    return Result.failure("No inserted coin found!") if @coin_transactions.blank?

    ActiveRecord::Base.transaction do
      update_pc_session!
      mark_transaction_used!
      deactivate_coin_slot_session!
      schedule_expiration
      queue_send_pc_command!
    end

    Result.success(@pc_session)
  rescue ActiveRecord::RecordInvalid => e
    Result.failure(e.message)
  end

  private

    def update_pc_session!
      total_minutes = @coin_transactions.sum(:minutes_granted)
      total_amount = @coin_transactions.sum(:peso_amount)
      expiration_datetime = @pc_session.expires_at + total_minutes.minutes
      total_minutes_purchased = @pc_session.total_minutes_purchased + total_minutes
      accumulated_total_amount = @pc_session.total_amount + total_amount

      @pc_session.update!(
        expires_at: expiration_datetime,
        total_minutes_purchased: total_minutes_purchased,
        total_amount: accumulated_total_amount
      )
    end

    def deactivate_coin_slot_session!
      if @coin_slot_session.present? && @coin_slot_session.active?
        @coin_slot_session.mark_inactive_and_disable_esp!
      end
    end

    def mark_transaction_used!
      @coin_transactions.each(&:used!)
    end

    def schedule_expiration
      PcSessionExpirationJob.set(wait_until: @pc_session.expires_at).perform_later(@pc_session.id)
    end

    def queue_send_pc_command!
      @pc.pc_command_logs.create!(
        command: :unlock,
        status: :pending,
        sent_at: Time.current
      )
    end
end
