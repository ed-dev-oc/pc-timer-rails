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

  test "should destroy coin_slot" do
    assert_difference("CoinSlot.count", -1) do
      delete admin_coin_slot_url(@coin_slot)
    end

    assert_redirected_to admin_coin_slots_url
  end

  test "should redirect admin actions when unauthenticated" do
    sign_out @admin
    get admin_coin_slots_url
    assert_redirected_to new_user_session_url

    post restart_admin_coin_slot_url(@coin_slot)
    assert_redirected_to new_user_session_url
  end

  test "should restart coin slot when authenticated" do
    @coin_slot.update!(status: :online)
    assert_difference("EspCommandLog.count", 1) do
      assert_enqueued_with(job: CoinSlots::EspCommandJob) do
        post restart_admin_coin_slot_url(@coin_slot)
      end
    end
    assert_redirected_to admin_coin_slot_url(@coin_slot.device_id)
    assert @coin_slot.reload.offline?
    assert_equal "restart", @coin_slot.esp_command_logs.order(:id).last.command
  end

  test "should toggle lock status when authenticated" do
    @coin_slot.update!(status: :online)
    
    patch toggle_lock_admin_coin_slot_url(@coin_slot)
    assert_redirected_to admin_coin_slot_url(@coin_slot.device_id)
    assert @coin_slot.reload.locked?

    patch toggle_lock_admin_coin_slot_url(@coin_slot)
    assert_redirected_to admin_coin_slot_url(@coin_slot.device_id)
    assert @coin_slot.reload.offline?
  end
end
