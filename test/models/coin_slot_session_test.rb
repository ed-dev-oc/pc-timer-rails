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
end
