class CoinSlot
  module Broadcasts
    class Session
      extend ActionView::RecordIdentifier

      def self.call(coin_slot)
        Turbo::StreamsChannel.broadcast_replace_to(
          "coin_slot_session",
          target: dom_id(coin_slot, :session),
          html: ApplicationController.render(
            Winform::CoinSlots::SessionComponent.new(coin_slot: coin_slot),
            layout: false
          )
        )
      end
    end
  end
end
