# frozen_string_literal: true

require "test_helper"

class Admin::CoinSlots::SessionComponentTest < ViewComponent::TestCase
  # Test rendering when there is no active session and no custom empty message.
  def test_renders_default_no_active_session_message
    coin_slot = CoinSlot.new
    # Stub the methods needed for the component.
    def coin_slot.has_current_active_session?
      false
    end
    def coin_slot.active_session
      nil
    end

    render_inline(Admin::CoinSlots::SessionComponent.new(coin_slot: coin_slot))

    assert_text "No Active Session"
  end

  # Test rendering with a custom empty_message.
  def test_renders_custom_empty_message
    coin_slot = CoinSlot.new
    def coin_slot.has_current_active_session?
      false
    end
    def coin_slot.active_session
      nil
    end

    render_inline(
      Admin::CoinSlots::SessionComponent.new(
        coin_slot: coin_slot,
        empty_message: "Nothing happening"
      )
    )

    assert_text "Nothing happening"
  end
end
