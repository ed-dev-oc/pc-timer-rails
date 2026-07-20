require "test_helper"

class CoinSlotSessionTest < ActiveSupport::TestCase
  test "valid fixture is valid" do
    session = coin_slot_sessions(:one)
    assert session.valid?
  end

  test "set_started_and_ended_at sets timestamps correctly" do
    coin_slot = coin_slots(:one)
    pc = pcs(:one)
    session = CoinSlotSession.create!(coin_slot: coin_slot, pc: pc)
    assert_not_nil session.started_at
    assert_not_nil session.ended_at
    expected_duration = Setting.duration("coin_slot_session_duration").seconds
    assert_in_delta expected_duration, (session.ended_at - session.started_at), 1
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
    first = CoinSlotSession.create!(coin_slot: coin_slot, pc: pc1)
    assert_equal "active", first.status
    # attempt second active session should be invalid
    second = CoinSlotSession.new(coin_slot: coin_slot, pc: pc2)
    second.status = :active
    refute second.valid?
    assert_includes second.errors[:base], "Coin slot currently used!"
  end

  test "mark_inactive_and_disable_esp! transitions status and creates esp command log" do
    coin_slot = coin_slots(:one)
    pc = pcs(:one)
    slot_session = CoinSlotSession.create!(coin_slot: coin_slot, pc: pc)
    assert_equal "active", slot_session.status
    assert_difference "EspCommandLog.count", 1 do
      slot_session.mark_inactive_and_disable_esp!
    end
    # The status should be updated to inactive within the same object
    assert_equal "inactive", slot_session.status
    log = EspCommandLog.last
    assert_equal "disable", log.command
    assert_equal "pending", log.status
    assert_equal coin_slot, log.coin_slot
    # The log does not store a direct association to the session (only coin_slot), so we skip this check.
  end
end
