require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
  end

  test "should redirect to login when unauthenticated" do
    get admin_root_url
    assert_redirected_to new_user_session_url
  end

  test "should get index when authenticated" do
    sign_in @admin
    get admin_root_url
    assert_response :success
  end

  test "should redirect to root with access denied when authenticated as regular user" do
    sign_in users(:two)
    get admin_root_url
    assert_redirected_to root_url
    assert_equal "Access denied.", flash[:alert]
  end
end
