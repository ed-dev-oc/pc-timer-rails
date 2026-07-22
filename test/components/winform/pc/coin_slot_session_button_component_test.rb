# frozen_string_literal: true

require "test_helper"

class Winform::Pc::CoinSlotSessionButtonComponentTest < ViewComponent::TestCase
  def test_renders_insert_coin_button_when_no_active_coin_slot_session
    pc = pcs(:one)
    render_inline(Winform::Pc::CoinSlotSessionButtonComponent.new(pc: pc))
    assert_selector "a", text: "Insert Coin"
  end

  def test_renders_cancel_button_when_active_coin_slot_session
    pc = pcs(:one)
    coin_slot = coin_slots(:one)
    # Create an active coin slot session for this PC
    CoinSlotSession.create!(pc: pc, coin_slot: coin_slot, status: :active)
    pc.reload
    render_inline(Winform::Pc::CoinSlotSessionButtonComponent.new(pc: pc))
    assert_selector "a", text: "Cancel"
  end
end
