require "test_helper"

class Admin::PcsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pc = pcs(:one)
  end

  test "should get index" do
    get admin_pcs_url
    assert_response :success
  end

  test "should get new" do
    get new_admin_pc_url
    assert_response :success
  end

  test "should create pc" do
    assert_difference("Pc.count") do
      post admin_pcs_url, params: { pc: {} }
    end

    assert_redirected_to admin_pc_url(Pc.last)
  end

  test "should show pc" do
    get admin_pc_url(@pc)
    assert_response :success
  end

  test "should get edit" do
    get edit_admin_pc_url(@pc)
    assert_response :success
  end

  test "should update pc" do
    patch admin_pc_url(@pc), params: { pc: {} }
    assert_redirected_to admin_pc_url(@pc)
  end

  test "should destroy pc" do
    assert_difference("Pc.count", -1) do
      delete admin_pc_url(@pc)
    end

    assert_redirected_to admin_pcs_url
  end
end
