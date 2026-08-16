module CoinSlots
  class StatusChangedAction
    extend ActionView::RecordIdentifier

    def self.call(coin_slot)
      Turbo::StreamsChannel.broadcast_replace_later_to(
        "badge_status",
        target: dom_id(coin_slot, :badge_status),
        partial: "shared/status_badge",
        locals: { object: coin_slot }
      )
    end
  end
end
