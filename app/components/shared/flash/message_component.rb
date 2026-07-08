# frozen_string_literal: true

class Shared::Flash::MessageComponent < ViewComponent::Base
  FLASH_TYPES = {
    notice:  { icon: '<i class="bi bi-check-circle-fill text-success"></i>'.html_safe, css_class: "text-bg-success" },
    alert:   { icon: '<i class="bi bi-exclamation-triangle-fill text-danger"></i>'.html_safe, css_class: "text-bg-danger" },
    error:   { icon: '<i class="bi bi-exclamation-circle-fill text-danger"></i>'.html_safe, css_class: "text-bg-danger" },
    success: { icon: '<i class="bi bi-check-circle-fill text-success"></i>'.html_safe, css_class: "text-bg-success" },
    info:    { icon: '<i class="bi bi-info-circle-fill text-primary"></i>'.html_safe, css_class: "text-bg-primary" },
    warning: { icon: '<i class="bi bi-exclamation-triangle-fill text-warning"></i>'.html_safe, css_class: "text-bg-warning" },
    danger: { icon: '<i class="bi bi-exclamation-triangle-fill text-danger"></i>'.html_safe, css_class: "text-bg-danger" }
  }.freeze

  def initialize(type:, message:)
    @type = type
    @message = message
  end

  def render?
    @message.present?
  end

  def icon
   flash_type(@type)[:icon]
  end

  def css_class
    flash_type(@type)[:css_class]
  end

  private

    def flash_type(type)
      FLASH_TYPES[type.to_sym] || { icon: '<i class="bi bi-bell text-secondary"></i>'.html_safe, css_class: "text-bg-secondary" }
    end
end
