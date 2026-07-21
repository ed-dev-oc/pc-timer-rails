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
        coin_slot.broadcast_badge_status
        coin_slot.broadcast_session
      end

      Pc::Broadcasts::PcSessionButtons.call(pc) if pc.present?
    end
  end
end
