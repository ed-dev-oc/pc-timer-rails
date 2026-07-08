# frozen_string_literal: true

require "test_helper"

class Shared::Flash::ContainerComponentTest < ViewComponent::TestCase
  # Verify that the turbo frame wrapper is rendered with the correct id and classes
  def test_renders_turbo_frame_with_correct_id_and_class
    render_inline(Shared::Flash::ContainerComponent.new(flash: {}))
    assert_selector "turbo-frame#flash_messages.toast-container.p-3.position-absolute.bottom-0.end-0"
  end

  # When no flash messages are present, the component should render the frame but no toast elements
  def test_renders_no_toasts_when_flash_empty
    render_inline(Shared::Flash::ContainerComponent.new(flash: {}))
    assert_no_selector ".toast"
  end

  # The component should render a toast for each flash message, preserving type and content
  def test_renders_multiple_flash_messages
    flash_hash = {
      "notice": [ "Saved successfully" ],
      "alert": [ "Something went wrong", "Another error" ]
    }
    render_inline(Shared::Flash::ContainerComponent.new(flash: flash_hash))

    # Expect three toast elements (one notice, two alerts)
    assert_selector ".toast", count: 3

    # Verify that each message text appears in the output
    assert_text "Saved successfully"
    assert_text "Something went wrong"
    assert_text "Another error"

    # Verify that the type titles are rendered (titleized)
    assert_text "Notice"
    assert_text "Alert"
  end
end
