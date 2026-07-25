# frozen_string_literal: true

module Pcs
  module Sessions
    class Create
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
          create_pc_session!
          deactivate_coin_slot_session!
          set_coin_slot_status_to_active!
          schedule_expiration
          active_pc_session!
          mark_transactions_used!
        end

        @pc.reload

        if @coin_slot.present?
          CoinSlot::Broadcasts::BadgeStatus.call(@coin_slot)
          CoinSlot::Broadcasts::Session.call(@coin_slot)
        end

        Pcs::Broadcasts::BadgeStatus.call(@pc)
        PcSessions::BroadcastService.call(@pc)

        Result.success(@pc_session)
      rescue ActiveRecord::RecordInvalid => e
        Result.failure(e.message)
      end

    private

      def create_pc_session!
        total_minutes = @coin_transactions.sum(:minutes_granted)
        total_amount = @coin_transactions.sum(:peso_amount)

        @pc_session = PcSession.create!(
          pc: @pc,
          total_minutes_purchased: total_minutes,
          total_amount: total_amount,
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

      def set_coin_slot_status_to_active!
        @coin_slot.active! if @coin_slot.present?
      end

      def active_pc_session!
        @pc.mark_active_session_and_unlock_pc!
      end

      def mark_transactions_used!
        @coin_transactions.each(&:used!)
      end
    end
  end
end
