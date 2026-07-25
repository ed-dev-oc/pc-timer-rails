require "test_helper"

class PcSessionTest < ActiveSupport::TestCase
  test "manual session does not require minimum coin credit" do
    pc_session = PcSession.new(
      pc: pcs(:one),
      total_minutes_purchased: 30,
      total_amount: 0,
      started_at: Time.current,
      expires_at: 30.minutes.from_now
    )

    assert pc_session.valid?
  end

  test "coin funded session requires unused coin total to meet minimum credit" do
    pc = pcs(:one)
    pc.coin_transactions.destroy_all
    Setting.set("minimum_credit", 5, "integer")

    pc.coin_transactions.create!(
      coin_slot: coin_slots(:one),
      transaction_uid: "pc-session-minimum-credit",
      peso_amount: 1
    )

    pc_session = PcSession.new(
      pc: pc,
      total_minutes_purchased: 30,
      total_amount: 1,
      started_at: Time.current,
      expires_at: 30.minutes.from_now
    )

    assert_not pc_session.valid?
    assert_includes pc_session.errors[:base], "Please insert ₱5 or more to play!"
  end
  test "total_remaining_seconds returns correct value for active session" do
    pc = pcs(:one)
    session = pc_sessions(:one)
    session.update!(expires_at: 1.hour.from_now, status: :active)
    remaining = session.total_remaining_seconds
    assert_in_delta 3600, remaining, 5
  end

  test "total_remaining_seconds returns zero when session ended" do
    session = pc_sessions(:one)
    session.update!(status: :ended)
    assert_equal 0, session.total_remaining_seconds
  end

  test "total_remaining_seconds returns zero when expired" do
    session = pc_sessions(:one)
    session.update!(expires_at: 1.hour.ago, status: :active)
    assert_equal 0, session.total_remaining_seconds
  end
end
