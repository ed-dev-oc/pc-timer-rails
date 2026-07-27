# frozen_string_literal: true

module Pcs
  module Sessions
    class Update
      def self.call(pc, pc_session)
        new(pc, pc_session).call
      end

      def initialize(pc, pc_session)
        @pc = pc
        @pc_session = pc_session
        # Preload related objects used throughout the service
        @coin_transactions = @pc.coin_transactions.unused
        @coin_slot_session = @pc.active_coin_slot_session
        @coin_slot = @coin_slot_session&.coin_slot
      end

      def call
        # Guard against missing coin transactions (no inserted coin)
        return Result.failure("No inserted coin found!") if @coin_transactions.blank?

        ActiveRecord::Base.transaction do
          update_pc_session!
          mark_transaction_used!
          deactivate_coin_slot_session!
          schedule_expiration
          queue_send_pc_command!
        end

        Pcs::Broadcasts::BadgeStatus.call(@pc)
        PcSessions::BroadcastService.call(@pc)

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
          total_amount: accumulated_total_amount,
          status: :active
        )
      end

      def deactivate_coin_slot_session!
        if @coin_slot_session.present? && @coin_slot_session.active?
          @coin_slot_session.stop_session!
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
  end
end
