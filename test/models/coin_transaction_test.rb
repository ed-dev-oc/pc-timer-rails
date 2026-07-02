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
end
