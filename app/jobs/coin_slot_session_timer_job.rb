class CoinSlotSessionTimerJob < ApplicationJob
  queue_as :default

  def perform(coin_slot_session_id)
    coin_slot_session = CoinSlotSession.find_by(id: coin_slot_session_id)

    if coin_slot_session.present? && coin_slot_session.active?
      coin_slot_session.mark_inactive_and_disable_esp!
    end
  end
end
