module CoinSlots
  class SessionTimerJob < ApplicationJob
    queue_as :default

    def perform(coin_slot_session_id)
      coin_slot_session = CoinSlotSession.find_by(id: coin_slot_session_id)
      return unless coin_slot_session
      return if coin_slot_session.ended?

      pc = coin_slot_session&.pc

      if coin_slot_session.expired?
        coin_slot = coin_slot_session.coin_slot
        coin_slot.stop_session! if coin_slot_session.active?

        CoinSlotSessions::ChangedAction.call(@coin_slot_session)

        if pc.present?
          pc.reload
          PcSessions::BroadcastService.call(pc)
        end
      end
    end
  end
end
