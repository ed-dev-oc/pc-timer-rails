class CoinSlotSessionTimerJob < ApplicationJob
  queue_as :default

  def perform(coin_slot_session_id)
    coin_slot_session = CoinSlotSession.find_by(id: coin_slot_session_id)
    coin_slot = coin_slot_session&.coin_slot
    pc = coin_slot_session&.pc

    if coin_slot_session.present? && coin_slot_session.active?
      coin_slot_session.mark_inactive_and_disable_esp!

      if coin_slot.present?
        coin_slot.active!
        CoinSlots::Broadcasts::BadgeStatus.call(coin_slot)
        CoinSlots::Broadcasts::Session.call(coin_slot)
      end

      PcSessions::BroadcastService.call(pc) if pc.present?
    end
  end
end
