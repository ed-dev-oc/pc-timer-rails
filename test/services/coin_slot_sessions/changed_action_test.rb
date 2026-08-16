require "test_helper"

class ChangedActionTest < ActiveSupport::TestCase
  test "broadcasts the session and triggers StatusChangedAction" do
    # Load a fixture CoinSlotSession
    coin_slot_session = coin_slot_sessions(:one)
    coin_slot = coin_slot_session.coin_slot

    # Capture the broadcast call
    broadcast_args = nil
    status_called = false
    Turbo::StreamsChannel.stub(:broadcast_replace_later_to, ->(*args) { broadcast_args = args }) do
      # Capture the call to the status‑changed service
      CoinSlots::StatusChangedAction.stub(:call, ->(_coin_slot) { status_called = true }) do
        CoinSlotSessions::ChangedAction.call(coin_slot_session)
      end
    end

    # Verify the broadcast was performed
    assert_not_nil broadcast_args, "Turbo broadcast should be invoked"
    assert_equal "coin_slot_session", broadcast_args[0]

    # The second argument is a hash of options; check the target DOM id
    expected_target = ActionView::RecordIdentifier.dom_id(coin_slot, :session)
    assert_equal expected_target, broadcast_args[1][:target]

    # Verify the status‑changed service was called
    assert status_called, "CoinSlots::StatusChangedAction.call should be invoked"
  end
end
