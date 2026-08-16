module Pcs
  class SessionControlsChanged
    COMPONENTS = {
      coin_slot_button: Winform::Pcs::CoinSlotSessionButtonComponent,
      pc_session_button: Winform::Pcs::PcSessionButtonComponent
    }.freeze

    def self.call(pc)
      COMPONENTS.each do |target, component|
        Turbo::StreamsChannel.broadcast_replace_later_to(
          target.to_s,
          target: ActionView::RecordIdentifier.dom_id(pc, target),
          html: ApplicationController.render(
            component.new(pc: pc),
            layout: false
          )
        )
      end
    end
  end
end
