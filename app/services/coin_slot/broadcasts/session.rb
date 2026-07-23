class CoinSlot
  module Broadcasts
    class Session
      extend ActionView::RecordIdentifier

      def self.call(coin_slot)
        Turbo::StreamsChannel.broadcast_replace_to(
          "coin_slot_session",
          target: dom_id(coin_slot, :session),
          partial: "winform/coin_slots/session",
          locals: { coin_slot: coin_slot }
        )
      end
    end
  end
end
