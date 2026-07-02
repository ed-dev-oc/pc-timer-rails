require "test_helper"

class CreatePcSessionTest < ActiveSupport::TestCase
  test "fails when unused coin total is below minimum credit" do
    pc = pcs(:one)
    pc.coin_transactions.destroy_all
    Setting.set("minimum_credit", 5, "integer")

    pc.coin_transactions.create!(
      coin_slot: coin_slots(:one),
      transaction_uid: "create-session-below-minimum",
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
      transaction_uid: "create-session-minimum-1",
      peso_amount: 2
    )
    pc.coin_transactions.create!(
      coin_slot: coin_slots(:one),
      transaction_uid: "create-session-minimum-2",
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
