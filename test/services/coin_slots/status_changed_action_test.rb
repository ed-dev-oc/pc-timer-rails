require "test_helper"

class StatusChangedActionTest < ActiveSupport::TestCase
  test "broadcasts badge status with correct DOM id and partial" do
    # Load a fixture CoinSlot
    coin_slot = coin_slots(:one)

    broadcast_args = nil
    Turbo::StreamsChannel.stub(:broadcast_replace_later_to, ->(*args) { broadcast_args = args }) do
      CoinSlots::StatusChangedAction.call(coin_slot)
    end

    assert_not_nil broadcast_args, "Turbo broadcast should be invoked"
    # Verify channel name
    assert_equal "badge_status", broadcast_args[0]
    # Verify options hash contains expected target, partial, and locals
    opts = broadcast_args[1]
    expected_target = ActionView::RecordIdentifier.dom_id(coin_slot, :badge_status)
    assert_equal expected_target, opts[:target]
    assert_equal "shared/status_badge", opts[:partial]
    assert_equal({ object: coin_slot }, opts[:locals])
  end
end
