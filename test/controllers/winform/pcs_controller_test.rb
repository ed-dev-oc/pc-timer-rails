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
end
