require "test_helper"

class UpdatePcSessionTest < ActiveSupport::TestCase
  test "adds unused coin total to session total amount" do
    pc = pcs(:one)
    pc.coin_transactions.destroy_all
    pc_session = pc_sessions(:one)
    pc_session.update!(status: :active, total_amount: 10, total_minutes_purchased: 60, expires_at: 1.hour.from_now)
    Setting.set("minimum_credit", 5, "integer")

    pc.coin_transactions.create!(
      coin_slot: coin_slots(:one),
      transaction_uid: "update-session-minimum-1",
      peso_amount: 2
    )
    pc.coin_transactions.create!(
      coin_slot: coin_slots(:one),
      transaction_uid: "update-session-minimum-2",
      peso_amount: 3
    )

    result = UpdatePcSession.call(pc, pc_session)

    assert result.success?
    assert_equal 15, pc_session.reload.total_amount
    assert_equal 90, pc_session.total_minutes_purchased
    assert pc.coin_transactions.used.exists?
    assert_not pc.coin_transactions.unused.exists?
  end
end
