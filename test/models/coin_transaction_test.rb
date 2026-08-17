require "test_helper"

class CoinTransactionTest < ActiveSupport::TestCase
  setup do
    @coin_transaction = coin_transactions(:one)
  end

  test "valid fixture is valid" do
    assert @coin_transaction.valid?
  end

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
      transaction_uid: @coin_transaction.transaction_uid,
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

  test "set_minutes_granted recalculates when peso amount changes" do
    Setting.set("minutes_per_credit", 3, "integer")

    @coin_transaction.update!(peso_amount: 4)

    assert_equal 12, @coin_transaction.reload.minutes_granted
  end

  test "mark_used! changes status to used" do
    @coin_transaction.update!(status: :unused)

    @coin_transaction.mark_used!

    assert @coin_transaction.reload.used?
  end

  test "unused scope excludes used transactions" do
    used_transaction = coin_transactions(:two)
    used_transaction.update!(status: :used)
    @coin_transaction.update!(status: :unused)

    unused_transactions = CoinTransaction.unused

    assert_includes unused_transactions, @coin_transaction
    assert_not_includes unused_transactions, used_transaction
  end

  test "insert_coin! creates an unused transaction with calculated minutes" do
    Setting.set("minutes_per_credit", 4, "integer")

    assert_difference("CoinTransaction.count", 1) do
      coin_transaction = CoinTransaction.insert_coin!(
        transaction_uid: "insert-coin-transaction",
        coin_slot: coin_slots(:one),
        pc: pcs(:one),
        peso_amount: 5
      )

      assert coin_transaction.unused?
      assert_equal 20, coin_transaction.minutes_granted
    end
  end

  test "update broadcasts changed transaction total for PC" do
    called_with = []

    CoinTransactions::BroadcastService.stub(:call, ->(pc) { called_with << pc }) do
      @coin_transaction.update!(status: :used)
    end

    assert_equal [ @coin_transaction.pc ], called_with
  end
end
