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
    pc_sessions(:one).update!(status: :ended)
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

  private

  def json_response
    JSON.parse(response.body)
  end
end
