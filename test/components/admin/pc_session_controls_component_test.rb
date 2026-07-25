# frozen_string_literal: true

require "test_helper"

class Admin::PcSessionControlsComponentTest < ViewComponent::TestCase
  def test_renders_unlock_button_when_no_active_session
    pc = pcs(:one)
    rendered = render_inline(Admin::PcSessionControlsComponent.new(pc: pc))
    # The component should render a button with class btn-success and the text "Unlock"
    assert_selector "button.btn-success" do
      assert_text "Unlock"
    end
  end

  def test_renders_lock_button_when_active_session_present
    pc = pcs(:one)
    # Create an active pc session for this pc
    pc_session = pc.pc_sessions.create!(
      total_minutes_purchased: 30,
      total_amount: 0,
      started_at: Time.current,
      expires_at: 30.minutes.from_now,
      status: :active
    )
    pc.reload
    rendered = render_inline(Admin::PcSessionControlsComponent.new(pc: pc))
    assert_selector "a.btn-warning" do
      assert_text "Lock"
    end
  end
end
