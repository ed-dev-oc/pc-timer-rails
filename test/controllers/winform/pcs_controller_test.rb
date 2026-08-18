require "test_helper"

class Winform::PcsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pc = pcs(:one)
    @pc.update!(status: :online)
  end

  test "should get show with valid HMAC signature" do
    path = winform_pc_path(@pc)
    headers = signed_headers(@pc, method: "GET", path: path)

    get path, headers: headers
    assert_response :success
  end

  test "should get error page without HMAC signature" do
    get error_winform_pcs_path
    assert_response :success
  end

  test "should get minimize page with valid HMAC signature" do
    path = minimize_winform_pc_path(@pc)
    headers = signed_headers(@pc, method: "GET", path: path)

    get path, headers: headers
    assert_response :success
  end

  test "should redirect to login/error or be unauthorized when access without signature" do
    get winform_pc_path(@pc)
    assert_response :unauthorized
  end
end
