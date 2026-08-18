require "test_helper"

class Api::CoinTransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @coin_slot = coin_slots(:one)
    @pc = pcs(:one)
    @coin_slot_session = coin_slot_sessions(:one)
    @coin_slot_session.update!(
      coin_slot: @coin_slot,
      pc: @pc,
      status: :active,
      public_uid: "coin-slot-session-one"
    )

    Setting.set("minutes_per_credit", 4, "integer")
  end

  test "creates coin transaction from signed coin slot request" do
    body = coin_transaction_body(transaction_uid: "esp-tx-001", peso_amount: 5)
    path = coin_transactions_path(@coin_slot_session)
    headers = signed_json_headers(@coin_slot, path: path, body: body)

    suppress_broadcast_services do
      assert_difference("CoinTransaction.count", 1) do
        post path, params: body, headers: headers
      end
    end

    coin_transaction = CoinTransaction.order(:id).last

    assert_response :created
    assert_equal "created", json_response["status"]
    assert_equal "esp-tx-001", json_response["transaction_uid"]
    assert_equal "esp-tx-001", coin_transaction.transaction_uid
    assert_equal 5, coin_transaction.peso_amount
    assert_equal 20, coin_transaction.minutes_granted
    assert_equal @coin_slot, coin_transaction.coin_slot
    assert_equal @pc, coin_transaction.pc
    assert coin_transaction.unused?
  end

  test "rejects coin transaction request without hmac headers" do
    body = coin_transaction_body(transaction_uid: "esp-tx-002", peso_amount: 5)

    assert_no_difference("CoinTransaction.count") do
      post coin_transactions_path(@coin_slot_session), params: body, headers: json_headers
    end

    assert_response :unauthorized
    assert_equal "UNAUTHORIZED", json_response["code"]
    assert_equal "Missing headers", json_response["detail"]
  end

  test "rejects coin transaction for missing coin slot session" do
    body = coin_transaction_body(transaction_uid: "esp-tx-003", peso_amount: 5)
    path = "/api/coin_slot_sessions/missing-session/coin_transactions"
    headers = signed_json_headers(@coin_slot, path: path, body: body)

    assert_no_difference("CoinTransaction.count") do
      post path, params: body, headers: headers
    end

    assert_response :not_found
    assert_equal "NOT_FOUND", json_response["code"]
    assert_equal "Coin slot session not found", json_response["detail"]
  end

  test "rejects invalid coin transaction params" do
    body = coin_transaction_body(transaction_uid: "", peso_amount: 5)
    path = coin_transactions_path(@coin_slot_session)
    headers = signed_json_headers(@coin_slot, path: path, body: body)

    suppress_broadcast_services do
      assert_no_difference("CoinTransaction.count") do
        post path, params: body, headers: headers
      end
    end

    assert_response :unprocessable_content
    assert_equal "VALIDATION_FAILED", json_response["code"]
    assert_equal "Failed to save coin transaction", json_response["detail"]
  end

  private

  def coin_transactions_path(coin_slot_session)
    "/api/coin_slot_sessions/#{coin_slot_session.public_uid}/coin_transactions"
  end

  def coin_transaction_body(transaction_uid:, peso_amount:)
    {
      coin_transaction: {
        transaction_uid: transaction_uid,
        peso_amount: peso_amount
      }
    }.to_json
  end

  def signed_json_headers(device, path:, body:)
    signed_headers(device, method: "POST", path: path, body: body).merge(json_headers)
  end

  def json_headers
    {
      "CONTENT_TYPE" => "application/json",
      "ACCEPT" => "application/json"
    }
  end

  def json_response
    JSON.parse(response.body)
  end

  def suppress_broadcast_services
    CoinTransactions::BroadcastService.stub(:call, ->(*) {}) do
      PcSessions::BroadcastService.stub(:call, ->(*) {}) do
        yield
      end
    end
  end
end
