module Admin::CoinSlotSessionsHelper
  BADGE_CLASSES = {
    active: "text-bg-success",
    inactive: "text-bg-secondary"
  }.freeze

  ICON_CLASSES = {
    active: "bi bi-play-circle-fill",
    inactive: "bi bi-stop-circle-fill"
  }

  def coin_slot_session_status_badge(coin_slot_session)
    content_tag(:span, class: "badge p-2 #{coin_slot_session_badge_class(coin_slot_session.status)}") do
      concat content_tag(:i, "", class: "#{ICON_CLASSES[coin_slot_session.status.to_sym]} me-1")
      concat coin_slot_session.status.titleize
    end
  end

  def coin_slot_session_badge_class(status)
    BADGE_CLASSES[status.to_sym]
  end
end
