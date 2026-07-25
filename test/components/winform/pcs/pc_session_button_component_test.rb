# frozen_string_literal: true

require "test_helper"

class Winform::Pcs::PcSessionButtonComponentTest < ViewComponent::TestCase
  def test_renders_use_credit_button_when_unused_coin_transaction_and_no_active_pc_session
    pc = pcs(:one)
    render_inline(Winform::Pcs::PcSessionButtonComponent.new(pc: pc))
    assert_selector "a", text: "Use Credit!"
  end

  def test_renders_extend_time_button_when_unused_coin_transaction_and_active_pc_session
    pc = pcs(:one)
    # Stub the active_pc_session method to simulate an existing session without persisting a record
    pc.stub(:active_pc_session, Object.new) do
      render_inline(Winform::Pcs::PcSessionButtonComponent.new(pc: pc))
      assert_selector "a", text: "Extend Time!"
    end
  end
end
