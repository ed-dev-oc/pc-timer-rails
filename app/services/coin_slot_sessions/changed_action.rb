module CoinSlotSessions
  class ChangedAction
    extend ActionView::RecordIdentifier

    def self.call(coin_slot_session)
      coin_slot = coin_slot_session.coin_slot

      broadcast_session(coin_slot)
      CoinSlots::StatusChangedAction.call(coin_slot)
    end

    private

      def self.broadcast_session(coin_slot)
        Turbo::StreamsChannel.broadcast_replace_later_to(
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
