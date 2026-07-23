require "test_helper"

class CoinSlotBroadcastsBadgeStatusTest < ActiveSupport::TestCase
  test "broadcast badge status uses Turbo::StreamsChannel" do
    coin_slot = coin_slots(:one)
    called = false
    expected_target = ActionView::RecordIdentifier.dom_id(coin_slot, :badge_status)

    Turbo::StreamsChannel.stub :broadcast_replace_to, ->(*args) do
      called = true
      stream_name, options = args
      assert_equal "badge_status", stream_name
      assert_equal expected_target, options[:target]
      assert_equal "shared/status_badge", options[:partial]
      assert_equal({ object: coin_slot }, options[:locals])
    end do
      CoinSlot::Broadcasts::BadgeStatus.call(coin_slot)
    end

    assert called, "Turbo::StreamsChannel.broadcast_replace_to was not called"
  end
end
