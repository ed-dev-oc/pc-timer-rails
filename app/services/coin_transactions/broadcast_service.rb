module CoinTransactions
  # Service object responsible for broadcasting updates related to a PC.
  # It is defined inside the CoinTransactions module namespace to avoid
  # constant name collisions with the CoinTransaction model.
  class BroadcastService
    include ActionView::RecordIdentifier
    # Performs the same broadcasting that was previously inside the CoinTransaction model.
    # It reloads the pc record to ensure fresh associations and then broadcasts
    # the updated badge as well as the coin slot and pc session button components.
    def self.call(pc)
      # Replace the total amount badge using the new view component.
      pc.broadcast_replace_to(
        "coin_transaction",
        target: ActionView::RecordIdentifier.dom_id(pc, :inserted_amount),
        html: ApplicationController.render(
          Winform::CoinTransactions::TotalAmountBadgeComponent.new(pc: pc),
          layout: false
        )
      )

      # pc.broadcast_replace_to(
      #   "coin_slot_button",
      #   target: ActionView::RecordIdentifier.dom_id(pc, :coin_slot_button),
      #   html: ApplicationController.render(
      #     Winform::Pc::CoinSlotSessionButtonComponent.new(pc: pc),
      #     layout: false
      #   )
      # )

      # pc.broadcast_replace_to(
      #   "pc_session_button",
      #   target: ActionView::RecordIdentifier.dom_id(pc, :pc_session_button),
      #   html: ApplicationController.render(
      #     Winform::Pc::PcSessionButtonComponent.new(pc: pc),
      #     layout: false
      #   )
      # )
    end
  end
end
