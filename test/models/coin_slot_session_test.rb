require "test_helper"

class CoinSlotSessionTest < ActiveSupport::TestCase
  test "valid fixture is valid" do
    session = coin_slot_sessions(:one)
    assert session.valid?
  end

  test "set_started_and_expires_at sets timestamps correctly and enqueues expiration job" do
    coin_slot = coin_slots(:one)
    pc = pcs(:one)
    session = nil
    # Ensure the expiration job is scheduled when we start a session
    assert_enqueued_with(job: CoinSlots::SessionTimerJob) do
      session = CoinSlotSession.start!(coin_slot, pc)
    end

    assert_not_nil session.started_at
    assert_not_nil session.expires_at
    expected_duration = Setting.duration("coin_slot_session_duration").seconds
    assert_in_delta expected_duration, (session.expires_at - session.started_at), 1
  end

  test "status validation only allows active on create" do
    coin_slot = coin_slots(:one)
    pc = pcs(:one)
    session = CoinSlotSession.new(coin_slot: coin_slot, pc: pc)
    # default status will be nil, validation should add error unless status is active
    session.status = :inactive
    refute session.valid?
    session.status = :active
    assert session.valid?
  end

  test "cannot create second active session for same coin slot" do
    coin_slot = coin_slots(:one)
    pc1 = pcs(:one)
    pc2 = pcs(:two)
    # first active session
    first = CoinSlotSession.start!(coin_slot, pc1)
    assert_equal "active", first.status
    # reload the coin slot to clear any cached association
    coin_slot = CoinSlot.find(coin_slot.id)
    # attempt second active session should be invalid – use a new instance so we can inspect validation errors
    second = CoinSlotSession.new(coin_slot: coin_slot, pc: pc2)
    second.status = :active
    refute second.valid?
    assert_includes second.errors[:base], "Coin slot currently used!"
  end

  test "start! raises when coin slot already has an active session" do
    coin_slot = coin_slots(:one)
    pc1 = pcs(:one)
    pc2 = pcs(:two)
    # first session succeeds
    CoinSlotSession.start!(coin_slot, pc1)
    # reload the coin slot to ensure the association cache is cleared
    coin_slot = CoinSlot.find(coin_slot.id)
    # second attempt should raise ActiveRecord::RecordInvalid
    assert_raises(ActiveRecord::RecordInvalid) do
      CoinSlotSession.start!(coin_slot, pc2)
    end
  end
end
