module PcSessions
  module BroadcastService
    include ActionView::RecordIdentifier

    def self.call(pc)
      Pcs::Broadcasts::PcSessionButtons.call(pc)

      Turbo::StreamsChannel.broadcast_replace_to(
        "pc_session",
        target: ActionView::RecordIdentifier.dom_id(pc, :pc_session),
        html: ApplicationController.render(
          Winform::Pcs::SessionPanelComponent.new(pc: pc),
          layout: false
        )
      )

      Turbo::StreamsChannel.broadcast_replace_to(
        "pc_session",
        target: ActionView::RecordIdentifier.dom_id(pc, :pc_session_minimize),
        html: ApplicationController.render(
          Winform::Pcs::MinimizeComponent.new(pc: pc),
          layout: false
        )
      )

      Turbo::StreamsChannel.broadcast_replace_to(
        "pc_session_controls",
        target: ActionView::RecordIdentifier.dom_id(pc, :pc_session_controls),
        html: ApplicationController.render(
          Admin::PcSessionControlsComponent.new(pc: pc),
          layout: false
        )
      )
    end
  end
end
