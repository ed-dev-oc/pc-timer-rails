class Pc
  module Sessions
    class Create
      def self.call(pc)
        new(pc).call
      end

      def initialize(pc)
        @pc = pc
      end

      def call
        unused = @pc.coin_transactions.unused
        return Result.failure("No inserted coin found") if unused.empty?

        total_amount = unused.sum(:peso_amount)
        minimum_credit = Setting.get("minimum_credit", 1)
        return Result.failure("Insufficient credit") if total_amount < minimum_credit

        minutes_per_credit = Setting.get("minutes_per_credit", 6)
        total_minutes = total_amount * minutes_per_credit

        started_at = Time.current
        expires_at = started_at + total_minutes.minutes
        pc_session = PcSession.create!(
          pc: @pc,
          total_amount: total_amount,
          total_minutes_purchased: total_minutes,
          total_minutes_used: 0,
          status: :active,
          started_at: started_at,
          expires_at: expires_at
        )
        @pc.update!(status: :active_session)

        # Mark coin transactions as used
        unused.update_all(status: :used)

        # Deactivate any active coin slot session and log disable command
        if (active_cs = @pc.active_coin_slot_session)
          active_cs.mark_inactive_and_disable_esp!
        end

        Pc::Broadcasts::BadgeStatus.call(@pc)
        Result.success(pc_session)
      rescue ActiveRecord::RecordInvalid => e
        Result.failure(e.message)
      end
    end
  end
end
