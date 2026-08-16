module Pcs
  class StatusChangedAction
    def self.call(pc)
      pc.broadcast_replace_later_to(
        "badge_status",
        target: ActionView::RecordIdentifier.dom_id(pc, :badge_status),
        partial: "shared/status_badge",
        locals: { object: pc }
      )
    end
  end
end
