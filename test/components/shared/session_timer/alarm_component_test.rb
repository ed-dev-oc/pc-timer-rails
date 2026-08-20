# frozen_string_literal: true

require "test_helper"

class Shared::SessionTimer::AlarmComponentTest < ViewComponent::TestCase
  def test_component_renders_something_useful
    # Verify that the component renders the hidden div with correct data attributes
    pc = pcs(:one)
    pc_session = pc.pc_sessions.create!(
      total_minutes_purchased: 30,
      total_amount: 0,
      started_at: Time.current,
      expires_at: 30.minutes.from_now,
      status: :active
    )
    pc.reload

    start_at_ms = 12345
    # Use an existing audio asset to avoid MissingAssetError in test environment
    source = "pc_default_beep.mp3"
    rendered = render_inline(
      Shared::SessionTimer::AlarmComponent.new(
        object: pc_session,
        source: source,
        start_at: start_at_ms
      )
    )

    assert_selector "div[data-controller='shared--session-timer--alarm'][data-shared--session-timer--alarm-expires-at-value='#{pc_session.expires_at}'][data-shared--session-timer--alarm-start-at-ms-value='#{start_at_ms}']"

    assert_selector "audio"
  end

  # When the object is nil the component should render nothing (no div or audio)
  def test_component_renders_nothing_when_object_nil
    source = "pc_default_beep.mp3"
    start_at_ms = 12345
    render_inline(Shared::SessionTimer::AlarmComponent.new(object: nil, source: source, start_at: start_at_ms))
    # No hidden div should be present
    assert_no_selector "div[data-controller='shared--session-timer--alarm']"
    # No audio tag should be rendered
    assert_no_selector "audio[data-shared--session-timer--alarm-target='beepSound']"
  end
end
