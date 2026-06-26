require "test_helper"

class Api::PcsControllerTest < ActionDispatch::IntegrationTest
  test "should get signin" do
    get api_pcs_signin_url
    assert_response :success
  end

  test "should get signout" do
    get api_pcs_signout_url
    assert_response :success
  end
end
