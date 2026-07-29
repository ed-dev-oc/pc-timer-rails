# frozen_string_literal: true

module Pcs
  module Sessions
    class Extend
      def self.call(pc, pc_session)
        new(pc, pc_session).call
      end

      def initialize(pc, pc_session)
        @pc = pc
        @pc_session = pc_session
        @coin_transactions = @pc.coin_transactions.unused
        @coin_slot_session = @pc.active_coin_slot_session
        @coin_slot = @coin_slot_session&.coin_slot
      end

      def call
        # Guard against missing coin transactions (no inserted coin)
        return Result.failure("No inserted coin found!") if @coin_transactions.blank?

        ActiveRecord::Base.transaction do
          @pc_session.extend!(@coin_transactions)
          @pc_session.schedule_expiration
          @pc.queue_pc_command!(:unlock)
          CoinTransaction.mark_used(@coin_transactions)
          @coin_slot_session&.stop_session! if @coin_slot_session&.active?
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
