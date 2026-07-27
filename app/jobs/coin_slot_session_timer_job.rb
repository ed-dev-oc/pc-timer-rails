class CoinSlotSessionTimerJob < ApplicationJob
  queue_as :default

  def perform(coin_slot_session_id)
    coin_slot_session = CoinSlotSession.find_by(id: coin_slot_session_id)
    pc = coin_slot_session&.pc

    if coin_slot_session.present? && coin_slot_session.active?
      coin_slot_session.stop_session!
      PcSessions::BroadcastService.call(pc) if pc.present?
    end
  end
end
