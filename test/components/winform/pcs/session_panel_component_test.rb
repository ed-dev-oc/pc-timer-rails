# frozen_string_literal: true

require "test_helper"

class Winform::Pcs::SessionPanelComponentTest < ViewComponent::TestCase
  def test_renders_no_active_session_message_when_no_session
    pc = pcs(:one)
    rendered = render_inline(Winform::Pcs::SessionPanelComponent.new(pc: pc))
    assert_text "No Active Session"
  end

  def test_renders_session_timer_when_active_session_present
    pc = pcs(:one)
    pc_session = pc.pc_sessions.create!(
      total_minutes_purchased: 30,
      total_amount: 0,
      started_at: Time.current,
      expires_at: 30.minutes.from_now,
      status: :active
    )
    pc.reload
    rendered = render_inline(Winform::Pcs::SessionPanelComponent.new(pc: pc))
    # Expect the countdown component to be rendered, which includes a data attribute
    assert_selector "small[data-session-timer-target='totalTime']"
  end
end
