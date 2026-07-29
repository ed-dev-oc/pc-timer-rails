require "test_helper"

# Tests for the service Pcs::Sessions::Start
# This mirrors the style of the existing service tests in the
# test/services directory (e.g. create_pc_session_test.rb, update_pc_session_test.rb).
# It verifies both the successful path (when the PC has unused coin
# transactions) and the failure path (when no unused coins are present).

class PcSessionsStartTest < ActiveSupport::TestCase
  test "successful start creates a session, marks PC active, uses coins and stops coin slot session" do
    pc = pcs(:one)                     # fixture with unused coin transactions
    coin_slot_session = pc.active_coin_slot_session

    # The service schedules an expiration job for the created PcSession.
    assert_enqueued_with(job: PcSessionExpirationJob) do
      result = Pcs::Sessions::Start.call(pc)
      assert result.success?, "Result should be successful"
      pc_session = result.value
      assert_instance_of PcSession, pc_session
      assert pc.active_session?, "PC should be marked as having an active session"
      # All unused coin transactions should now be marked used.
      assert pc.coin_transactions.used.exists?, "Coin transactions should be marked used"
      assert_not pc.coin_transactions.unused.exists?, "No unused coin transactions should remain"
      # If a coin slot session existed it should be stopped.
      if coin_slot_session
        assert_equal "inactive", coin_slot_session.reload.status
      end
    end
  end

  test "failure when no inserted coin found" do
    pc = pcs(:two)                     # fixture without unused coins (all are used in fixtures)
    # Ensure the fixture truly has no unused coins for this test.
    pc.coin_transactions.update_all(status: :used)
    result = Pcs::Sessions::Start.call(pc)
    refute result.success?, "Result should be a failure"
    assert_match /No inserted coin found!/, result.error
  end
end
