module ApplicationHelper
  def flash_bootstrap_icon(key)
    case key.to_sym
    when :success, :notice
      '<i class="bi bi-check-circle-fill"></i>'.html_safe
    when :info
      '<i class="bi bi-info-circle-fill"></i>'.html_safe
    when :warning, :danger, :alert
      '<i class="bi bi-exclamation-triangle-fill"></i>'.html_safe
    else
      '<i class="bi bi-check-circle-fill"></i>'.html_safe
    end
  end
end
