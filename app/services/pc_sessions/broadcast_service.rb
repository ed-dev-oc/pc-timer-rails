module PcSessions
  module BroadcastService
    include ActionView::RecordIdentifier

    def self.call(pc)
      Pcs::StatusChangedAction.call(pc)
      Pcs::SessionControlsChanged.call(pc)
      broadcast_session_panel_component(pc)
      broadcast_minimize_component(pc)
      broadcast_admin_session_controls(pc)
      broadcast_coin_slot_state(pc)
    end

    private

      def self.broadcast_session_panel_component(pc)
        Turbo::StreamsChannel.broadcast_replace_later_to(
          "pc_session",
          target: ActionView::RecordIdentifier.dom_id(pc, :pc_session),
          html: ApplicationController.render(
            Winform::Pcs::SessionPanelComponent.new(pc: pc),
            layout: false
          )
        )
      end

      def self.broadcast_minimize_component(pc)
        Turbo::StreamsChannel.broadcast_replace_later_to(
          "pc_session",
          target: ActionView::RecordIdentifier.dom_id(pc, :pc_session_minimize),
          html: ApplicationController.render(
            Winform::Pcs::MinimizeComponent.new(pc: pc),
            layout: false
          )
        )
      end

      def self.broadcast_admin_session_controls(pc)
        Turbo::StreamsChannel.broadcast_replace_later_to(
          "pc_session_controls",
          target: ActionView::RecordIdentifier.dom_id(pc, :pc_session_controls),
          html: ApplicationController.render(
            Admin::PcSessionControlsComponent.new(pc: pc),
            layout: false
          )
        )
      end

      def self.broadcast_coin_slot_state(pc)
        coin_slot_session = pc&.coin_slot_sessions&.last

        return unless coin_slot_session

        CoinSlotSessions::ChangedAction.call(coin_slot_session)
      end
  end
end
