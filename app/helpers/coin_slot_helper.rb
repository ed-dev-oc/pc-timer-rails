module CoinSlotHelper
  # :active, :active_session, :offline
  BADGE_CLASSES = {
    active: "text-bg-success",
    active_session: "text-bg-primary",
    offline: "text-bg-danger",
    locked: "text-bg-dark"
  }.freeze

  ICON_CLASSES = {
    active: "bi bi-wifi",
    active_session: "bi bi-person-check",
    offline: "bi bi-wifi-off",
    locked: "bi bi-lock"
  }

  def coin_slot_status_badge(coin_slot)
    content_tag(:span, class: "badge p-2 #{coin_slot_badge_class(coin_slot.status)}") do
      concat content_tag(:i, "", class: "#{ICON_CLASSES[coin_slot.status.to_sym]} me-1")
      concat coin_slot.status.titleize
    end
  end

  def coin_slot_badge_class(status)
    BADGE_CLASSES[status.to_sym]
  end
end
