module CommandLogsHelper
  BADGE_CLASSES = {
    pending: "text-bg-secondary",
    sent: "text-bg-primary",
    success: "text-bg-success",
    failed: "text-bg-danger"
  }.freeze

  ICON_CLASSES = {
    pending: "bi bi-hourglass-split",
    sent: "bi bi-send-check",
    success: "bi bi-check-circle-fill",
    failed: "bi bi-x-circle-fill"
  }

  def command_log_status_badge(command_log)
    content_tag(:span, class: "badge p-2 #{command_log_badge_class(command_log.status)}") do
      concat content_tag(:i, "", class: "#{ICON_CLASSES[command_log.status.to_sym]} me-1")
      concat command_log.status.titleize
    end
  end

  def command_log_badge_class(status)
    BADGE_CLASSES[status.to_sym]
  end
end
