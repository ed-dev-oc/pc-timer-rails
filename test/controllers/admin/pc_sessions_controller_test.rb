require "test_helper"

class Admin::PcSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @pc = pcs(:one)
    @pc_session = pc_sessions(:one)
    @pc_session.update!(status: :active)
  end

  test "should redirect create when unauthenticated" do
    assert_no_difference("PcSession.count") do
      post admin_pc_pc_sessions_url(@pc), params: { pc_session: { total_minutes_purchased: 30 } }
    end
    assert_redirected_to new_user_session_url
  end

  test "should redirect stop_session when unauthenticated" do
    post stop_session_admin_pc_pc_session_url(@pc, @pc_session)
    assert_redirected_to new_user_session_url
  end

  test "should create manual session when authenticated" do
    sign_in @admin
    @pc.pc_sessions.destroy_all # Make sure there is no active session on this PC

    suppress_broadcast_service do
      assert_difference("PcSession.count", 1) do
        post admin_pc_pc_sessions_url(@pc), params: { pc_session: { total_minutes_purchased: 30 } }
      end
    end

    assert_redirected_to admin_pc_path(@pc.device_id)
    assert_equal "Session created to #{@pc.name}!", flash[:notice]

    new_session = PcSession.order(:created_at).last
    assert_equal @pc, new_session.pc
    assert_equal 30, new_session.total_minutes_purchased
    assert_equal 0, new_session.total_amount
  end

  test "should stop session when authenticated" do
    sign_in @admin
    @pc.update!(status: :active)

    suppress_broadcast_service do
      post stop_session_admin_pc_pc_session_url(@pc, @pc_session)
    end

    assert_redirected_to admin_pc_path(@pc.device_id)
    assert_equal "Session stop to #{@pc.name}!", flash[:notice]

    assert @pc_session.reload.stopped?
    assert @pc.reload.online?
  end

  private

  def suppress_broadcast_service
    PcSessions::BroadcastService.stub(:call, ->(*) {}) do
      yield
    end
  end
end
