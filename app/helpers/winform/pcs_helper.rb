module Winform::PcsHelper
  BADGE_CLASSES = {
    offline: "text-bg-secondary",
    online: "text-bg-primary",
    active_session: "text-bg-warning",
    disabled_kiosk: "text-bg-danger",
    uninstalled: "text-bg-dark"
  }.freeze

  ICON_CLASSES = {
    offline: "bi bi-wifi-off",
    online: "bi bi-wifi",
    active_session: "bi bi-person-check",
    disabled_kiosk: "bi bi-lock",
    uninstalled: "bi bi-trash3"
  }

  def pc_status_badge(pc)
    content_tag(:span, class: "badge p-2 #{pc_badge_class(pc.status)}") do
      concat content_tag(:i, "", class: "#{ICON_CLASSES[pc.status.to_sym]} me-1")
      concat pc.status.titleize
    end
  end

  def pc_badge_class(status)
    BADGE_CLASSES[status.to_sym]
  end
end
