class Pc
  module Broadcasts
    class UpdatedPcButton
      COMPONENTS = {
        coin_slot_button: Winform::Pc::CoinSlotSessionButtonComponent,
        pc_session_button: Winform::Pc::PcSessionButtonComponent
      }.freeze

      def self.call(pc_session)
        pc = pc_session.pc.reload

        COMPONENTS.each do |target, component|
          Turbo::StreamsChannel.broadcast_replace_to(
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
end
