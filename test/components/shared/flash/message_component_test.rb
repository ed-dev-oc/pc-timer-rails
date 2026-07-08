# frozen_string_literal: true

require "test_helper"

class Shared::Flash::MessageComponentTest < ViewComponent::TestCase
  # Mapping of flash types to expected icon CSS class and toast background class
  FLASH_TYPE_EXPECTATIONS = {
    notice:  { icon_class: "bi-check-circle-fill", css_class: "text-bg-success" },
    alert:   { icon_class: "bi-exclamation-triangle-fill", css_class: "text-bg-danger" },
    error:   { icon_class: "bi-exclamation-circle-fill", css_class: "text-bg-danger" },
    success: { icon_class: "bi-check-circle-fill", css_class: "text-bg-success" },
    info:    { icon_class: "bi-info-circle-fill", css_class: "text-bg-primary" },
    warning: { icon_class: "bi-exclamation-triangle-fill", css_class: "text-bg-warning" },
    danger:  { icon_class: "bi-exclamation-triangle-fill", css_class: "text-bg-danger" }
  }.freeze

  # Verify that each defined flash type renders the correct CSS class and icon
  def test_renders_each_flash_type_correctly
    FLASH_TYPE_EXPECTATIONS.each do |type, expectation|
      render_inline(Shared::Flash::MessageComponent.new(type: type.to_s, message: "Test message"))
      assert_selector ".toast.#{expectation[:css_class]}"
      # Icon element should contain the expected Bootstrap Icons class
      assert_selector "i.bi.#{expectation[:icon_class]}"
      # The type title should be present (titleized)
      assert_text type.to_s.titleize
      # The message text should be present
      assert_text "Test message"
    end
  end

  # When an unknown type is supplied, the component should fall back to the default icon and class
  def test_unknown_type_uses_default_fallback
    render_inline(Shared::Flash::MessageComponent.new(type: "unknown", message: "Msg"))
    assert_selector ".toast.text-bg-secondary"
    assert_selector "i.bi.bi-bell"
    assert_text "Unknown"
    assert_text "Msg"
  end

  # The component should not render any markup when the message is blank
  def test_blank_message_does_not_render
    render_inline(Shared::Flash::MessageComponent.new(type: "notice", message: ""))
    assert_no_selector "div.toast"
  end
end
