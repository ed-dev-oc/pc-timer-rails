require "test_helper"

class Admin::CoinSlotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @coin_slot = coin_slots(:one)
  end

  test "should get index" do
    get admin_coin_slots_url
    assert_response :success
  end

  test "should get new" do
    get new_admin_coin_slot_url
    assert_response :success
  end

  test "should create coin_slot" do
    assert_difference("CoinSlot.count") do
      post admin_coin_slots_url, params: { coin_slot: {} }
    end

    assert_redirected_to admin_coin_slot_url(CoinSlot.last)
  end

  test "should show coin_slot" do
    get admin_coin_slot_url(@coin_slot)
    assert_response :success
  end

  test "should get edit" do
    get edit_admin_coin_slot_url(@coin_slot)
    assert_response :success
  end

  test "should update coin_slot" do
    patch admin_coin_slot_url(@coin_slot), params: { coin_slot: {} }
    assert_redirected_to admin_coin_slot_url(@coin_slot)
  end

  test "should destroy coin_slot" do
    assert_difference("CoinSlot.count", -1) do
      delete admin_coin_slot_url(@coin_slot)
    end

    assert_redirected_to admin_coin_slots_url
  end
end
