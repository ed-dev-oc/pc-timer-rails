class CoinSlotSessionTimerJob < ApplicationJob
  queue_as :default

  def perform(coin_slot_session_id)
    coin_slot_session = CoinSlotSession.find_by(id: coin_slot_session_id)
    pc = coin_slot_session&.pc

    if coin_slot_session.present?
      coin_slot_session.stop_session! if coin_slot_session.active?

      if pc.present?
        pc.reload
        PcSessions::BroadcastService.call(pc)
      end
    end
  end
end
