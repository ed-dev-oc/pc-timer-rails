# frozen_string_literal: true

require "test_helper"

class Shared::SessionTimer::ProgressBarComponentTest < ViewComponent::TestCase
  test "renders progress bar when session is present" do
    coin_slot = coin_slots(:one)
    pc = pcs(:one)
    session = CoinSlotSession.create!(coin_slot: coin_slot, pc: pc)

    render_inline Shared::SessionTimer::ProgressBarComponent.new(
      object: session,
      session_object: session,
      session_duration_ms: Setting.duration("coin_slot_session_duration") * 1000,
      expires_at: session.ended_at
    )

    # The component should render a turbo frame with a deterministic DOM id
    assert_selector "turbo-frame##{dom_id(session, :progress_bar)}"
    # Inside the frame there must be a progress bar element
    assert_selector "div.progress div.progress-bar"
    # Verify the Stimulus controller data attribute is present
    assert_selector "div[data-controller='shared--session-timer--progress-bar']"
  end

  test "does not render when session_object is nil" do
    render_inline Shared::SessionTimer::ProgressBarComponent.new(
      object: nil,
      session_object: nil,
      session_duration_ms: 0,
      expires_at: Time.current
    )

    # When render? returns false, nothing should be rendered
    assert_no_selector "turbo-frame"
  end
end
