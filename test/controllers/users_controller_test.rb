require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:one)
    @user = users(:two)
  end

  test "should redirect to login if unauthenticated" do
    get settings_url
    assert_redirected_to new_user_session_path
    follow_redirect!
    assert_select "h3", "Log in"
  end

  test "should get settings page when authenticated as admin" do
    sign_in @admin
    get settings_url
    assert_response :success
    assert_select "span.fs-4", text: "ADMIN"
    assert_select "h4", "Account Settings"
    assert_select "input[type=email][value=?]", @admin.email
  end

  test "should get settings page when authenticated as regular user" do
    sign_in @user
    get settings_url
    assert_response :success
    assert_select "span.fs-4", text: "ADMIN", count: 0
    assert_select "h4", "Account Settings"
    assert_select "input[type=email][value=?]", @user.email
  end

  test "should update email successfully" do
    sign_in @user
    patch settings_url, params: { user: { email: "updated_user@example.com" } }
    assert_redirected_to settings_url
    follow_redirect!
    assert_match "Account settings updated successfully.", response.body
    @user.reload
    assert_equal "updated_user@example.com", @user.email
  end

  test "should update password successfully" do
    sign_in @user
    patch settings_url, params: { user: { password: "newpassword123", password_confirmation: "newpassword123" } }
    assert_redirected_to settings_url
    follow_redirect!
    assert_match "Account settings updated successfully.", response.body

    # Assert password was changed by verifying authentication
    assert @user.reload.valid_password?("newpassword123")
  end

  test "should not update settings with invalid email" do
    sign_in @user
    patch settings_url, params: { user: { email: "" } }
    assert_response :unprocessable_entity
    assert_select "div.alert-danger", /Please correct the following errors/
    assert_select "li", "Email can't be blank"
  end

  test "should not update password if confirmation mismatch" do
    sign_in @user
    patch settings_url, params: { user: { password: "newpassword123", password_confirmation: "mismatch" } }
    assert_response :unprocessable_entity
    assert_select "div.alert-danger", /Please correct the following errors/
    assert_select "li", "Password confirmation doesn't match Password"
  end
end
