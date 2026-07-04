require "test_helper"

class Admin::CoinSlotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    sign_in @admin
    @coin_slot = coin_slots(:one)
  end

  test "should get index" do
    get admin_coin_slots_url
    assert_response :success
  end

  test "should show coin_slot" do
    get admin_coin_slot_url(@coin_slot)
    assert_response :success
  end

  test "should update coin_slot" do
    patch admin_coin_slot_url(@coin_slot), params: { coin_slot: { name: "Updated Name" } }
    assert_redirected_to admin_coin_slot_url(@coin_slot)
    assert_equal "Updated Name", @coin_slot.reload.name
  end

  test "should destroy coin_slot" do
    assert_difference("CoinSlot.count", -1) do
      delete admin_coin_slot_url(@coin_slot)
    end

    assert_redirected_to admin_coin_slots_url
  end
end
