# frozen_string_literal: true

module Pcs
  module Sessions
    class StartManual
      def self.call(pc_session)
        new(pc_session).call
      end

      def initialize(pc_session)
        @pc_session = pc_session
        @pc = pc_session.pc
      end

      def call
        ActiveRecord::Base.transaction do
          @pc_session.save!
          @pc_session.schedule_expiration
          @pc.mark_active_session_and_unlock_pc!
        end

        @pc.broadcast_badge!
        @pc.broadcast_session!

        Result.success(@pc_session)
      rescue ActiveRecord::RecordInvalid => e
        Result.failure(e.message)
      end
    end
  end
end
