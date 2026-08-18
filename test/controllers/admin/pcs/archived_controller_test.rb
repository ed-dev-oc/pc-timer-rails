require "test_helper"

class Admin::Pcs::ArchivedControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @user = users(:two)
    @pc = pcs(:one)
    @pc.update!(status: :online)
  end

  test "admin can archive a PC" do
    sign_in @admin
    suppress_broadcasts do
      post admin_pc_archived_path(@pc)
    end

    assert_response :moved_permanently
    assert_redirected_to admin_pc_path(@pc.device_id)
    assert @pc.reload.archived?
    assert_equal "Status set to Archived.", flash[:notice]
  end

  test "admin can unarchive an archived PC" do
    @pc.update_columns(status: Pc.statuses[:archived])
    sign_in @admin
    suppress_broadcasts do
      delete admin_pc_archived_path(@pc)
    end

    assert_response :moved_permanently
    assert_redirected_to admin_pc_path(@pc.device_id)
    assert @pc.reload.unarchived?
    assert_equal "Status set to Unarchived.", flash[:notice]
  end

  test "regular user cannot archive a PC" do
    sign_in @user
    post admin_pc_archived_path(@pc)

    assert_redirected_to root_path
    assert_equal "Access denied.", flash[:alert]
    assert_not @pc.reload.archived?
  end

  test "regular user cannot unarchive a PC" do
    @pc.update_columns(status: Pc.statuses[:archived])
    sign_in @user
    delete admin_pc_archived_path(@pc)

    assert_redirected_to root_path
    assert_equal "Access denied.", flash[:alert]
    assert @pc.reload.archived?
  end

  test "unauthenticated user is redirected to login on archive" do
    post admin_pc_archived_path(@pc)
    assert_redirected_to new_user_session_path
    assert_not @pc.reload.archived?
  end

  test "unauthenticated user is redirected to login on unarchive" do
    @pc.update_columns(status: Pc.statuses[:archived])
    delete admin_pc_archived_path(@pc)
    assert_redirected_to new_user_session_path
    assert @pc.reload.archived?
  end
end
