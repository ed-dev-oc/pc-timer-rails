require "test_helper"

class Admin::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
  end

  test "show seeds missing default settings" do
    Setting.delete_all

    assert_difference("Setting.count", Setting::DEFAULTS.size) do
      get admin_settings_url
    end

    assert_response :success
    assert_equal "Internet Cafe", Setting.get("business_name")
    assert_equal "iCafe", Setting.get("app_name")
  end

  test "update saves submitted setting values" do
    Setting.ensure_defaults!
    business_name = Setting.find_by!(key: "business_name")
    app_name = Setting.find_by!(key: "app_name")

    patch admin_settings_url, params: {
      settings: {
        business_name.id => { value: "Corner Cafe" },
        app_name.id => { value: "Timer Desk" }
      }
    }

    assert_redirected_to admin_settings_url
    assert_equal "Corner Cafe", business_name.reload.value
    assert_equal "Timer Desk", app_name.reload.value
  end

  test "update rolls back all setting changes when any submitted value is invalid" do
    Setting.ensure_defaults!
    business_name = Setting.find_by!(key: "business_name")
    app_name = Setting.find_by!(key: "app_name")

    patch admin_settings_url, params: {
      settings: {
        business_name.id => { value: "Corner Cafe" },
        app_name.id => { value: "" }
      }
    }

    assert_response :unprocessable_content
    assert_equal "Internet Cafe", business_name.reload.value
    assert_equal "iCafe", app_name.reload.value
  end
end
