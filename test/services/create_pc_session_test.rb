require "test_helper"
require "securerandom"

# Consolidated test suite for the `CreatePcSession` service. Previously the file
# contained two separate `CreatePcSessionTest` classes, which caused duplicate
# constant definitions and made the test suite harder to maintain. The tests
# have been merged into a single class while preserving their original
# behavior.
class CreatePcSessionTest < ActiveSupport::TestCase
  test "successful creation with unused coin transactions creates pc session and deactivates active coin slot session" do
    pc = pcs(:one)
    # Ensure there is an active coin slot session for this pc
    coin_slot = coin_slots(:one)

    prev_count = coin_slot.esp_command_logs.where(command: :disable).count
    active_session = CoinSlotSession.create!(coin_slot: coin_slot, pc: pc)
    # Ensure there is at least one unused coin transaction for the pc (fixture provides one)
    assert_not_empty pc.coin_transactions.unused
    result = CreatePcSession.call(pc)
    assert result.success?
    pc_session = result.value
    assert_instance_of PcSession, pc_session
    # PC should be marked active
    pc.reload
    assert pc.active?
    # Active coin slot session should be marked inactive and have a disable esp log
    active_session.reload
    assert_equal "inactive", active_session.status
    # The fixtures already contain one disable log for this coin slot, and the
    # service creates an additional one when deactivating the active session.
    assert_equal prev_count + 1, coin_slot.esp_command_logs.where(command: :disable).count
  end

  test "failure when no unused coin transactions" do
    pc = pcs(:two)
    # Ensure pc two has no unused transactions (remove them)
    pc.coin_transactions.update_all(status: :used)
    result = CreatePcSession.call(pc)
    refute result.success?
    assert_match /No inserted coin found/, result.error
  end

  test "fails when unused coin total is below minimum credit" do
    pc = pcs(:one)
    pc.coin_transactions.destroy_all
    Setting.set("minimum_credit", 5, "integer")

    pc.coin_transactions.create!(
      coin_slot: coin_slots(:one),
      transaction_uid: "create-session-below-minimum-#{SecureRandom.hex(4)}",
      peso_amount: 1
    )

    result = CreatePcSession.call(pc)
    assert_not result.success?
  end

  test "creates session with total amount from unused coin transactions" do
    pc = pcs(:one)
    pc.coin_transactions.destroy_all
    Setting.set("minimum_credit", 5, "integer")

    pc.coin_transactions.create!(
      coin_slot: coin_slots(:one),
      transaction_uid: "create-session-minimum-1-#{SecureRandom.hex(4)}",
      peso_amount: 2
    )
    pc.coin_transactions.create!(
      coin_slot: coin_slots(:one),
      transaction_uid: "create-session-minimum-2-#{SecureRandom.hex(4)}",
      peso_amount: 3
    )

    result = CreatePcSession.call(pc)
    assert result.success?
    assert_equal 5, result.value.total_amount
    assert_equal 30, result.value.total_minutes_purchased
    assert pc.coin_transactions.used.exists?
    assert_not pc.coin_transactions.unused.exists?
  end
end
