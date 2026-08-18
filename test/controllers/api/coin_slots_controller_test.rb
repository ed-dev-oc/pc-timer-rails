require "test_helper"

class Api::CoinSlotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @coin_slot = coin_slots(:one)
    @coin_slot.update!(status: :online)
  end

  # --- Registration ---

  test "should register a new coin slot with valid params" do
    assert_difference("CoinSlot.count", 1) do
      post "/api/coin_slots/register", params: {
        coin_slot: {
          name: "New Coin Slot",
          ip_address: "192.168.1.150",
          mac_address: "00:aa:bb:cc:dd:ee",
          device_id: "new-coin-slot-device"
        }
      }
    end

    assert_response :ok
    assert_equal "success", json_response["status"]
    assert_not_nil json_response["coin_slot_id"]
    assert_equal "new-coin-slot-device", json_response["device_id"]
    assert_not_nil json_response["secret"]
  end

  test "should reject registration with invalid/missing params" do
    assert_no_difference("CoinSlot.count") do
      post "/api/coin_slots/register", params: {
        coin_slot: {
          name: "",
          ip_address: "",
          mac_address: "",
          device_id: ""
        }
      }
    end

    assert_response :unprocessable_entity
    assert_equal "VALIDATION_FAILED", json_response["code"]
  end

  # --- Heartbeat ---

  test "should post heartbeat and set to online when no active session exists" do
    path = "/api/coin_slots/#{@coin_slot.device_id}/heartbeat"
    body_params = {
      coin_slot: {
        name: "Coin Slot One",
        ip_address: "192.168.1.120",
        mac_address: "00:11:22:33:44:55"
      }
    }
    headers = signed_headers(@coin_slot, method: "POST", path: path, body: body_params.to_json)

    suppress_broadcasts do
      post path, params: body_params, headers: headers, as: :json
    end

    assert_response :ok
    assert_equal "success", json_response["status"]
    assert_equal "online", json_response["coin_slot_status"]
    
    @coin_slot.reload
    assert_equal "online", @coin_slot.status
    assert_equal "192.168.1.120", @coin_slot.ip_address
    assert_in_delta Time.current, @coin_slot.last_seen_at, 5.seconds
  end

  test "should post heartbeat and set to active when active session exists" do
    pc = pcs(:one)
    coin_slot_sessions(:one).update!(
      coin_slot: @coin_slot,
      pc: pc,
      status: :active,
      expires_at: 10.minutes.from_now
    )
    @coin_slot.update!(status: :active)

    path = "/api/coin_slots/#{@coin_slot.device_id}/heartbeat"
    body_params = {
      coin_slot: {
        name: "Coin Slot One",
        ip_address: "192.168.1.120",
        mac_address: "00:11:22:33:44:55"
      }
    }
    headers = signed_headers(@coin_slot, method: "POST", path: path, body: body_params.to_json)

    suppress_broadcasts do
      post path, params: body_params, headers: headers, as: :json
    end

    assert_response :ok
    assert_equal "success", json_response["status"]
    assert_equal "active", json_response["coin_slot_status"]
    
    @coin_slot.reload
    assert_equal "active", @coin_slot.status
  end

  # --- HMAC auth boundary ---

  test "heartbeat request without HMAC headers is rejected" do
    path = "/api/coin_slots/#{@coin_slot.device_id}/heartbeat"

    post path, params: {
      coin_slot: { ip_address: "192.168.1.120" }
    }, as: :json

    assert_response :unauthorized
    assert_equal "UNAUTHORIZED", json_response["code"]
    assert_equal "Missing headers", json_response["detail"]
  end

  test "heartbeat request with invalid HMAC signature is rejected" do
    path = "/api/coin_slots/#{@coin_slot.device_id}/heartbeat"
    body_params = { coin_slot: { ip_address: "192.168.1.120" } }
    headers = signed_headers(@coin_slot, method: "POST", path: path, body: body_params.to_json)
    headers["X-SIGNATURE"] = "deadbeef" * 8

    post path, params: body_params, headers: headers, as: :json

    assert_response :unauthorized
    assert_equal "UNAUTHORIZED", json_response["code"]
    assert_equal "Invalid signature", json_response["detail"]
  end

  test "heartbeat request with expired timestamp is rejected" do
    path = "/api/coin_slots/#{@coin_slot.device_id}/heartbeat"
    body_params = { coin_slot: { ip_address: "192.168.1.120" } }
    stale_timestamp = 10.minutes.ago.to_i
    headers = signed_headers(@coin_slot, method: "POST", path: path, timestamp: stale_timestamp, body: body_params.to_json)

    post path, params: body_params, headers: headers, as: :json

    assert_response :unauthorized
    assert_equal "UNAUTHORIZED", json_response["code"]
    assert_equal "Expired request", json_response["detail"]
  end

  test "locked coin slot heartbeat is rejected even with valid HMAC" do
    @coin_slot.update_columns(status: CoinSlot.statuses[:locked])
    path = "/api/coin_slots/#{@coin_slot.device_id}/heartbeat"
    body_params = { coin_slot: { ip_address: "192.168.1.120" } }
    headers = signed_headers(@coin_slot, method: "POST", path: path, body: body_params.to_json)

    post path, params: body_params, headers: headers, as: :json

    assert_response :unauthorized
    assert_equal "UNAUTHORIZED", json_response["code"]
    assert_equal "Invalid device", json_response["detail"]
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
