# frozen_string_literal: true

module Pcs
  module Sessions
    class Stop
      def self.call(pc, pc_session)
        new(pc, pc_session).call
      end

      def initialize(pc, pc_session)
        @pc = pc
        @pc_session = pc_session
      end

      def call
        ActiveRecord::Base.transaction do
          end_pc_session!
          online_and_lock_pc!
        end

        @pc.reload
        Pcs::Broadcasts::BadgeStatus.call(@pc)
        PcSessions::BroadcastService.call(@pc)

        Result.success(@pc_session)
      rescue ActiveRecord::RecordInvalid => e
        Result.failure(e.message)
      end

    private

      def end_pc_session!
        current_time = Time.current
        total_minutes_used = (current_time - @pc_session.started_at).ceil / 60

        @pc_session.update!(
          status: :ended,
          total_minutes_used: total_minutes_used
        )
      end

      def online_and_lock_pc!
        @pc.mark_online_and_lock_pc!
      end
    end
  end
end
