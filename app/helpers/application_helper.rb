module ApplicationHelper
  def toast_attributes(key)
    attributes = {}

    case key.to_sym
    when :success, :notice
      attributes[:icon] = '<i class="bi bi-check-circle-fill text-success"></i>'.html_safe
      attributes[:text_bg] = "text-bg-success"
    when :info
      attributes[:icon] = '<i class="bi bi-info-circle-fill text-primary"></i>'.html_safe
      attributes[:text_bg] = "text-bg-primary"
    when :warning, :danger, :alert
      attributes[:icon] = '<i class="bi bi-exclamation-triangle-fill text-danger"></i>'.html_safe
      attributes[:text_bg] = "text-bg-danger"
    else
      attributes[:icon] = '<i class="bi bi-bell text-secondary"></i>'.html_safe
      attributes[:text_bg] = "text-bg-secondary"
    end

    attributes
  end
end
