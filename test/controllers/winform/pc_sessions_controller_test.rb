require "test_helper"

class Winform::PcSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pc = pcs(:one)
    @pc.update!(status: :online)
    @pc.pc_sessions.update_all(status: PcSession.statuses[:stopped])

    @coin_transaction = coin_transactions(:one)
    @coin_transaction.update_columns(
      pc_id: @pc.id,
      status: CoinTransaction.statuses[:unused],
      peso_amount: 5,
      minutes_granted: 12
    )

    clear_enqueued_jobs
  end

  test "signed pc starts a session from unused coin transactions" do
    path = winform_pc_pc_sessions_path(@pc)
    headers = signed_headers(@pc, method: "POST", path: path)

    suppress_broadcast_service do
      assert_difference("PcSession.count", 1) do
        assert_difference("Command.count", 1) do
          post path, headers: headers
        end
      end
    end

    pc_session = PcSession.order(:id).last

    assert_redirected_to winform_pc_path(@pc.device_id)
    assert_equal @pc, pc_session.pc
    assert pc_session.active?
    assert_equal 12, pc_session.total_minutes_purchased
    assert_equal 5, pc_session.total_amount
    assert @coin_transaction.reload.used?
    assert @pc.reload.active?
    assert_equal "unlock", @pc.commands.order(:id).last.commandable.action
  end

  test "signed pc extends active session from unused coin transactions" do
    pc_session = pc_sessions(:one)
    pc_session.update!(
      pc: @pc,
      status: :active,
      total_minutes_purchased: 30,
      total_amount: 10,
      expires_at: 15.minutes.from_now
    )
    original_expires_at = pc_session.reload.expires_at

    path = winform_pc_pc_session_path(@pc, pc_session)
    headers = signed_headers(@pc, method: "PATCH", path: path)

    suppress_broadcast_service do
      assert_no_difference("PcSession.count") do
        assert_difference("Command.count", 1) do
          patch path, headers: headers
        end
      end
    end

    assert_redirected_to winform_pc_path(@pc.device_id)
    assert pc_session.reload.active?
    assert_equal 42, pc_session.total_minutes_purchased
    assert_equal 15, pc_session.total_amount
    assert_equal original_expires_at + 12.minutes, pc_session.expires_at
    assert @coin_transaction.reload.used?
    assert @pc.reload.active?
    assert_equal "unlock", @pc.commands.order(:id).last.commandable.action
  end

  test "signed pc is redirected when starting without inserted coins" do
    @pc.coin_transactions.destroy_all

    path = winform_pc_pc_sessions_path(@pc)
    headers = signed_headers(@pc, method: "POST", path: path)

    suppress_broadcast_service do
      assert_no_difference("PcSession.count") do
        post path, headers: headers
      end
    end

    assert_redirected_to winform_pc_path(@pc.device_id)
    assert_equal "No inserted coin found.", flash[:alert]
  end

  test "signed pc is redirected when extending without active session" do
    @pc.pc_sessions.update_all(status: PcSession.statuses[:stopped])

    path = winform_pc_pc_session_path(@pc, pc_sessions(:one))
    headers = signed_headers(@pc, method: "PATCH", path: path)

    assert_no_difference("Command.count") do
      patch path, headers: headers
    end

    assert_redirected_to winform_pc_path(@pc.device_id)
    assert_equal "PC session not found!", flash[:alert]
  end

  private

  def suppress_broadcast_service
    PcSessions::BroadcastService.stub(:call, ->(*) { }) do
      yield
    end
  end
end
