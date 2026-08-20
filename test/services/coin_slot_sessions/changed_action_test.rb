require "test_helper"

class ChangedActionTest < ActiveSupport::TestCase
  test "broadcasts the session and triggers StatusChangedAction" do
    # Load a fixture CoinSlotSession
    coin_slot_session = coin_slot_sessions(:one)
    coin_slot = coin_slot_session.coin_slot

    # Capture the broadcast calls (both user and admin streams)
    broadcast_calls = []
    status_called = false
    Turbo::StreamsChannel.stub(:broadcast_replace_later_to, ->(*args) { broadcast_calls << args }) do
      # Capture the call to the status‑changed service
      CoinSlots::StatusChangedAction.stub(:call, ->(_coin_slot) { status_called = true }) do
        CoinSlotSessions::ChangedAction.call(coin_slot_session)
      end
    end

    # Verify the broadcasts were performed for both streams
    assert_not_empty broadcast_calls, "Turbo broadcasts should be invoked"
    # Expect two broadcasts: one for the user stream and one for the admin stream
    assert_equal 2, broadcast_calls.size, "Expected two broadcast calls"

    # Validate each broadcast call's stream name and target DOM id
    expected_target = ActionView::RecordIdentifier.dom_id(coin_slot, :session)
    stream_names = broadcast_calls.map { |args| args[0] }
    targets = broadcast_calls.map { |args| args[1][:target] }
    assert_includes stream_names, "coin_slot_session"
    assert_includes stream_names, "admin_coin_slot_session"
    assert_equal [ expected_target, expected_target ], targets, "Both broadcasts should target the same DOM id"

    # Verify the status‑changed service was called
    assert status_called, "CoinSlots::StatusChangedAction.call should be invoked"
  end
end
