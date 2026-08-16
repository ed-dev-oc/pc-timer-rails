module CoinTransactions
  module BroadcastService
    include ActionView::RecordIdentifier

    def self.call(pc)
      pc.broadcast_replace_later_to(
        "coin_transaction",
        target: ActionView::RecordIdentifier.dom_id(pc, :inserted_amount),
        html: ApplicationController.render(
          Winform::CoinTransactions::TotalAmountBadgeComponent.new(pc: pc),
          layout: false
        )
      )
    end
  end
end
