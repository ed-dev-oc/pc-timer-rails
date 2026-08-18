require "test_helper"

class Api::PcsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pc = pcs(:one)
    @pc.update!(status: :online)
  end

  test "should post signin and set to active_session when active session exists" do
    pc_sessions(:one).update!(status: :active)
    path = "/api/pcs/#{@pc.device_id}/signin"
    headers = signed_headers(@pc, method: "POST", path: path)

    post path, headers: headers
    assert_response :ok
    assert_equal "success", json_response["status"]
    assert_equal "active", @pc.reload.status
  end

  test "should post signin and set to online when no active session exists" do
    pc_sessions(:one).update!(status: :stopped)
    path = "/api/pcs/#{@pc.device_id}/signin"
    headers = signed_headers(@pc, method: "POST", path: path)

    post path, headers: headers
    assert_response :ok
    assert_equal "success", json_response["status"]
    assert_equal "online", @pc.reload.status
  end

  test "should post signout with valid hmac" do
    path = "/api/pcs/#{@pc.device_id}/signout"
    headers = signed_headers(@pc, method: "POST", path: path)

    post path, headers: headers
    assert_response :ok
    assert_equal "success", json_response["status"]
    assert @pc.reload.offline?
  end

  # --- Registration ---

  test "should register a new pc with valid params" do
    assert_difference("Pc.count", 1) do
      post "/api/pcs/register", params: {
        pc: {
          name: "New PC",
          ip_address: "192.168.1.180",
          mac_address: "00:aa:bb:cc:dd:ff",
          device_id: "new-pc-device"
        }
      }
    end

    assert_response :ok
    assert_equal "success", json_response["status"]
    assert_not_nil json_response["pc_id"]
    assert_equal "new-pc-device", json_response["device_id"]
    assert_not_nil json_response["secret"]
  end

  test "should reject registration with invalid/missing params" do
    assert_no_difference("Pc.count") do
      post "/api/pcs/register", params: {
        pc: {
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
    pc_sessions(:one).update!(status: :stopped)
    path = "/api/pcs/#{@pc.device_id}/heartbeat"
    body_params = {
      pc: {
        ip_address: "192.168.1.120",
        mac_address: "00:11:22:33:44:55"
      }
    }
    headers = signed_headers(@pc, method: "POST", path: path, body: body_params.to_json)

    suppress_broadcasts do
      post path, params: body_params, headers: headers, as: :json
    end

    assert_response :ok
    assert_equal "success", json_response["status"]
    assert_equal "online", json_response["pc"]["status"]
    assert_nil json_response["session"]

    @pc.reload
    assert_equal "online", @pc.status
    assert_equal "192.168.1.120", @pc.ip_address
  end

  test "should post heartbeat and set to active when active session exists" do
    session = pc_sessions(:one)
    session.update!(
      pc: @pc,
      status: :active,
      expires_at: 10.minutes.from_now
    )
    @pc.update!(status: :active)

    path = "/api/pcs/#{@pc.device_id}/heartbeat"
    body_params = {
      pc: {
        ip_address: "192.168.1.120",
        mac_address: "00:11:22:33:44:55"
      }
    }
    headers = signed_headers(@pc, method: "POST", path: path, body: body_params.to_json)

    suppress_broadcasts do
      post path, params: body_params, headers: headers, as: :json
    end

    assert_response :ok
    assert_equal "success", json_response["status"]
    assert_equal "active", json_response["pc"]["status"]
    assert_not_nil json_response["session"]
    assert_equal session.public_uid, json_response["session"]["id"]

    @pc.reload
    assert_equal "active", @pc.status
  end

  # --- HMAC auth boundary ---

  test "request without HMAC headers is rejected" do
    path = "/api/pcs/#{@pc.device_id}/signin"

    post path

    assert_response :unauthorized
    assert_equal "UNAUTHORIZED", json_response["code"]
    assert_equal "Missing headers", json_response["detail"]
  end

  test "request with invalid HMAC signature is rejected" do
    path = "/api/pcs/#{@pc.device_id}/signin"
    headers = signed_headers(@pc, method: "POST", path: path)
    headers["X-SIGNATURE"] = "deadbeef" * 8  # wrong signature, correct length format

    post path, headers: headers

    assert_response :unauthorized
    assert_equal "UNAUTHORIZED", json_response["code"]
    assert_equal "Invalid signature", json_response["detail"]
  end

  test "request with expired timestamp is rejected" do
    path = "/api/pcs/#{@pc.device_id}/signin"
    stale_timestamp = 10.minutes.ago.to_i
    headers = signed_headers(@pc, method: "POST", path: path, timestamp: stale_timestamp)

    post path, headers: headers

    assert_response :unauthorized
    assert_equal "UNAUTHORIZED", json_response["code"]
    assert_equal "Expired request", json_response["detail"]
  end

  test "archived device is rejected even with valid HMAC" do
    @pc.update_columns(status: Pc.statuses[:archived])
    path = "/api/pcs/#{@pc.device_id}/signin"
    headers = signed_headers(@pc, method: "POST", path: path)

    post path, headers: headers

    assert_response :unauthorized
    assert_equal "UNAUTHORIZED", json_response["code"]
    assert_equal "Invalid device", json_response["detail"]
  end

  # --- Session status JSON contract ---

  test "session_status returns active session details when session is present" do
    session = pc_sessions(:one)
    expires_at = 30.minutes.from_now.change(usec: 0)
    session.update_columns(
      pc_id: @pc.id,
      status: PcSession.statuses[:active],
      started_at: Time.current,
      expires_at: expires_at
    )
    @pc.update_columns(status: Pc.statuses[:active])

    path = "/api/pcs/#{@pc.device_id}/session_status"
    headers = signed_headers(@pc, method: "GET", path: path)

    get path, headers: headers

    assert_response :ok
    body = json_response
    assert_equal "active", body["pc_status"]
    assert_not_nil body["session"]
    assert_equal session.public_uid, body["session"]["id"]
    assert_equal "active", body["session"]["status"]
    assert_not_nil body["session"]["expires_at_utc"]
    assert_not_nil body["last_server_time"]
  end

  test "session_status returns null session when no active session" do
    @pc.pc_sessions.update_all(status: PcSession.statuses[:stopped])
    @pc.update!(status: :online)

    path = "/api/pcs/#{@pc.device_id}/session_status"
    headers = signed_headers(@pc, method: "GET", path: path)

    get path, headers: headers

    assert_response :ok
    assert_equal "online", json_response["pc_status"]
    assert_nil json_response["session"]
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
