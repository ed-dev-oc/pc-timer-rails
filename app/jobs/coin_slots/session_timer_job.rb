module CoinSlots
  class SessionTimerJob < ApplicationJob
    queue_as :default

    def perform(coin_slot_session_id)
      coin_slot_session = CoinSlotSession.find_by(id: coin_slot_session_id)
      pc = coin_slot_session&.pc

      if coin_slot_session.present?
        coin_slot = coin_slot_session.coin_slot
        coin_slot.stop_session! if coin_slot_session.active?

        CoinSlots::Broadcasts::BadgeStatus.call(coin_slot)
        CoinSlots::Broadcasts::Session.call(coin_slot)

        if pc.present?
          pc.reload
          PcSessions::BroadcastService.call(pc)
        end
      end
    end
  end
end
