class Session::CustomPcSession
  def self.call(pc_session)
    new(pc_session).call
  end

  def initialize(pc_session)
    @pc_session = pc_session
    @pc = pc_session.pc
  end

  def call
    ActiveRecord::Base.transaction do
      create_pc_session!
      schedule_expiration
      active_pc_session!
    end

    @pc.reload

    Result.success(@pc_session)
  rescue ActiveRecord::RecordInvalid => e
    Result.failure(e.message)
  end

  private

    def create_pc_session!
      @pc_session.update!(
        started_at: Time.current,
        expires_at: Time.current + @pc_session.total_minutes_purchased.minutes
      )
    end

    def schedule_expiration
      PcSessionExpirationJob.set(wait_until: @pc_session.expires_at).perform_later(@pc_session.id)
    end

    def active_pc_session!
      @pc.mark_active_session_and_unlock_pc!
    end
end
