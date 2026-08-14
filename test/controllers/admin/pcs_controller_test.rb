require "test_helper"

class Admin::PcsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    sign_in @admin
    @pc = pcs(:one)
  end

  test "should get index" do
    get admin_pcs_url
    assert_response :success
  end

  test "should show pc" do
    get admin_pc_url(@pc)
    assert_response :success
  end

  test "should update pc" do
    patch admin_pc_url(@pc), params: { pc: { name: "Updated PC Name" } }
    assert_redirected_to admin_pc_url(@pc)
    assert_equal "Updated PC Name", @pc.reload.name
  end

  test "should archive pc via destroy" do
    assert_no_difference("Pc.count") do
      delete admin_pc_url(@pc)
    end

    @pc.reload
    assert @pc.archived?, "PC should be archived after destroy"
    assert_redirected_to admin_pcs_url
  end
end
