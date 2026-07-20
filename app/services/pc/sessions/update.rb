class Pc
  module Sessions
    class Update
      def self.call(pc, pc_session)
        new(pc, pc_session).call
      end

      def initialize(pc, pc_session)
        @pc = pc
        @pc_session = pc_session
      end

      def call
        unused = @pc.coin_transactions.unused
        if unused.exists?
          added_amount = unused.sum(:peso_amount)
          minutes_per_credit = Setting.get("minutes_per_credit", 6)
          added_minutes = added_amount * minutes_per_credit

          @pc_session.update!(
            total_amount: @pc_session.total_amount + added_amount,
            total_minutes_purchased: @pc_session.total_minutes_purchased + added_minutes,
            status: :active
          )
          unused.update_all(status: :used)
        else
          @pc_session.update!(status: :active)
        end
        @pc.broadcast_badge_status
        Result.success(@pc_session)
      rescue ActiveRecord::RecordInvalid => e
        Result.failure(e.message)
      end
    end
  end
end
