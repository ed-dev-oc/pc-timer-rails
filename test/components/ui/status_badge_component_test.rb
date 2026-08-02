# frozen_string_literal: true

require "test_helper"
require "ostruct"

class Ui::StatusBadgeComponentTest < ViewComponent::TestCase
  # Mapping of status values to the expected CSS variant class and Bootstrap Icon class
  STATUS_EXPECTATIONS = {
    "active"          => { variant: "text-bg-success",   icon: "bi-play-circle-fill" },
    "inactive"        => { variant: "text-bg-secondary", icon: "bi-stop-circle-fill" },
    "offline"         => { variant: "text-bg-secondary", icon: "bi-wifi-off" },
    "online"          => { variant: "text-bg-primary",   icon: "bi-wifi" },
    "disabled_kiosk" => { variant: "text-bg-danger",    icon: "bi-lock" },
    "uninstalled"     => { variant: "text-bg-dark",      icon: "bi-trash3" },
    "used"            => { variant: "text-bg-success",   icon: "bi-check-circle-fill" },
    "unused"          => { variant: "text-bg-secondary", icon: "bi-circle" },
    "ended"           => { variant: "text-bg-secondary", icon: "bi-stop-circle-fill" },
    "locked"          => { variant: "text-bg-dark",      icon: "bi-lock-fill" },
    "pending"         => { variant: "text-bg-secondary", icon: "bi-hourglass-split" },
    "sent"            => { variant: "text-bg-primary",   icon: "bi-send-check" },
    "success"         => { variant: "text-bg-success",   icon: "bi-check-circle-fill" },
    "failed"          => { variant: "text-bg-danger",    icon: "bi-x-circle-fill" }
  }.freeze

  # Verify that each defined status renders the correct variant, icon, and titleized text
  # Dummy object that mimics an ActiveRecord model for `dom_id` helper
  class DummyStatusObject
    include ActiveModel::Model
    attr_accessor :status
  end

  def test_renders_each_status_correctly
    STATUS_EXPECTATIONS.each do |status, expectation|
      obj = DummyStatusObject.new(status: status)
      render_inline(Ui::StatusBadgeComponent.new(object: obj))
      assert_selector "span.badge.p-2.#{expectation[:variant]}"
      assert_selector "i.bi.#{expectation[:icon]}"
      assert_text status.titleize
    end
  end

  # When an unknown status is supplied, the component should fall back to the defaults
  def test_unknown_status_uses_default_fallback
    obj = DummyStatusObject.new(status: "unknown_status")
    render_inline(Ui::StatusBadgeComponent.new(object: obj))
    assert_selector "span.badge.p-2.text-bg-secondary"
    assert_selector "i.bi.bi-question-circle"
    assert_text "Unknown_status".titleize
  end
end
