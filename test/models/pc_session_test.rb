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
end
