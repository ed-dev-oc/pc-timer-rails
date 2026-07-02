module Admin::PcSessionsHelper
  BADGE_CLASSES = {
    active: "text-bg-success",
    ended: "text-bg-secondary"
  }.freeze

  ICON_CLASSES = {
    active: "bi bi-play-circle-fill",
    ended: "bi bi-stop-circle-fill"
  }

  def pc_session_status_badge(pc_session)
    content_tag(:span, class: "badge p-2 #{pc_session_badge_class(pc_session.status)}") do
      concat content_tag(:i, "", class: "#{ICON_CLASSES[pc_session.status.to_sym]} me-1")
      concat pc_session.status.titleize
    end
  end

  def pc_session_badge_class(status)
    BADGE_CLASSES[status.to_sym]
  end
end
