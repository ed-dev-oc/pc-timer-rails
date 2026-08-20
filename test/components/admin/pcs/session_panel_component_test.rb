# frozen_string_literal: true

require "test_helper"

class Admin::Pcs::SessionPanelComponentTest < ViewComponent::TestCase
  def test_component_renders_something_useful
    # Ensure the component renders without errors when given a PC without an active session.
    pc = pcs(:one)
    render_inline(Admin::Pcs::SessionPanelComponent.new(pc: pc))
    # The component should display a message indicating no active session.
    assert_selector "p", text: "No Active Session"
  end

  def test_component_renders_active_session_details
    # Create a PC with an active session to test the active branch of the component.
    pc = Pc.create!(
      name: "Test PC",
      device_id: "test-pc",
      ip_address: "127.0.0.1",
      mac_address: "AA:BB:CC:DD:EE:FF",
      status: :active,
      secret: "sk_test"
    )

    pc_session = PcSession.create!(
      pc: pc,
      total_minutes_purchased: 5,
      total_amount: 0,
      started_at: Time.current,
      expires_at: 1.hour.from_now,
      status: :active
    )

    render_inline(Admin::Pcs::SessionPanelComponent.new(pc: pc))
    # Verify that the total time element displays the formatted duration of the session.
    assert_selector "small[data-session-timer-target=\"totalTime\"]", text: pc_session.total_duration_formatted
  end
end
