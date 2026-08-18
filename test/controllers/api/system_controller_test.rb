require "test_helper"

class Api::SystemControllerTest < ActionDispatch::IntegrationTest
  test "should get server time" do
    freeze_time do
      get api_server_time_url
      assert_response :success
      
      json = JSON.parse(response.body)
      assert_equal Time.current.to_i, json["server_time"]
    end
  end
end
