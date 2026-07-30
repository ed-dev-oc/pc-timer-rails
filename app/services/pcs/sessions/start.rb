# frozen_string_literal: true

module Pcs
  module Sessions
    class Start
      def self.call(pc)
        new(pc).call
      end

      def initialize(pc)
        @pc = pc
        @coin_transactions = pc.coin_transactions.unused
        @coin_slot_session = pc.active_coin_slot_session
        @coin_slot = @coin_slot_session&.coin_slot
        @pc_session = nil
      end

      def call
        return Result.failure("No inserted coin found!") if @coin_transactions.blank?

        ActiveRecord::Base.transaction do
          @pc_session = PcSession.start!(@pc, @coin_transactions)

          @pc_session.schedule_expiration

          @pc.mark_active_session_and_unlock_pc!

          @coin_transactions.each(&:mark_used!)

          @coin_slot_session&.stop_session! if @coin_slot_session&.active?
        end

        @pc.reload
        @pc.broadcast_badge!
        @pc.broadcast_session!

        Result.success(@pc_session)
      rescue ActiveRecord::RecordInvalid => e
        Result.failure(e.message)
      end
    end
  end
end
