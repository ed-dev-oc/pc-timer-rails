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

  test "should redirect admin actions when unauthenticated" do
    sign_out @admin
    get admin_pcs_url
    assert_redirected_to new_user_session_url

    post restart_admin_pc_url(@pc)
    assert_redirected_to new_user_session_url
  end

  test "should restart pc when authenticated" do
    @pc.update!(status: :online)
    assert_difference("Command.count", 1) do
      assert_enqueued_with(job: ClientCommandJob) do
        post restart_admin_pc_url(@pc)
      end
    end
    assert_redirected_to admin_pc_url(@pc)
    assert @pc.reload.offline?
    assert_equal "restart", @pc.commands.order(:id).last.action
  end

  test "should shutdown pc when authenticated" do
    @pc.update!(status: :online)
    assert_difference("Command.count", 1) do
      assert_enqueued_with(job: ClientCommandJob) do
        post shutdown_admin_pc_url(@pc)
      end
    end
    assert_redirected_to admin_pc_url(@pc)
    assert @pc.reload.offline?
    assert_equal "shutdown", @pc.commands.order(:id).last.action
  end

  test "should toggle kiosk status when authenticated" do
    @pc.update_columns(status: Pc.statuses[:enabled_kiosk])

    suppress_broadcasts do
      post enable_or_disabled_kiosk_admin_pc_url(@pc)
    end

    assert_redirected_to admin_pc_url(@pc)
    assert @pc.reload.disabled_kiosk?

    suppress_broadcasts do
      post enable_or_disabled_kiosk_admin_pc_url(@pc)
    end

    assert_redirected_to admin_pc_url(@pc)
    assert @pc.reload.enabled_kiosk?
  end
end
