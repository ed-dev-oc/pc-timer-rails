require "test_helper"

class CoinTransactionTest < ActiveSupport::TestCase
  test "allows peso amount below minimum credit" do
    Setting.set("minimum_credit", 5, "integer")

    coin_transaction = CoinTransaction.new(
      transaction_uid: "below-minimum-credit",
      coin_slot: coin_slots(:one),
      pc: pcs(:one),
      peso_amount: 1
    )

    assert coin_transaction.valid?
  end


  test "validations and uniqueness" do
    dup = CoinTransaction.new(
      transaction_uid: coin_transactions(:one).transaction_uid,
      coin_slot: coin_slots(:one),
      pc: pcs(:one),
      peso_amount: 5,
      minutes_granted: 5,
      status: :unused
    )
    refute dup.valid?
    assert_includes dup.errors[:transaction_uid], "has already been taken"
  end

  test "numeric constraints" do
    tx = CoinTransaction.new(
      transaction_uid: "unique",
      coin_slot: coin_slots(:one),
      pc: pcs(:one),
      peso_amount: -1,
      minutes_granted: 0,
      status: :unused
    )
    refute tx.valid?
    assert_includes tx.errors[:peso_amount], "must be greater than 0"
    assert_includes tx.errors[:minutes_granted], "must be greater than 0"
  end

  test "set_minutes_granted uses Setting" do
    Setting.stub :integer, 2 do
      tx = CoinTransaction.new(
        transaction_uid: "new_tx",
        coin_slot: coin_slots(:one),
        pc: pcs(:one),
        peso_amount: 3,
        status: :unused
      )
      assert_nil tx.minutes_granted
      tx.valid?
      assert_equal 6, tx.minutes_granted
    end
  end
end
