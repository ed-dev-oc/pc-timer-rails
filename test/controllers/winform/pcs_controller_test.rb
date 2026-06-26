require "test_helper"

class Winform::PcsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get winform_pcs_show_url
    assert_response :success
  end
end
