require "test_helper"

class CoinSlotBroadcastsSessionTest < ActiveSupport::TestCase
  test "broadcast session uses Turbo::StreamsChannel" do
    coin_slot = coin_slots(:one)
    called = false
    expected_target = ActionView::RecordIdentifier.dom_id(coin_slot, :session)

    Turbo::StreamsChannel.stub :broadcast_replace_to, ->(*args) do
      called = true
      stream_name, options = args
      assert_equal "coin_slot_session", stream_name
      assert_equal expected_target, options[:target]
      assert_equal "winform/coin_slots/session", options[:partial]
      assert_equal({ coin_slot: coin_slot }, options[:locals])
    end do
      CoinSlot::Broadcasts::Session.call(coin_slot)
    end

    assert called, "Turbo::StreamsChannel.broadcast_replace_to was not called"
  end
end
