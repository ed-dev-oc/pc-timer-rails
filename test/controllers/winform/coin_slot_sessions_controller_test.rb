require "test_helper"

class Winform::CoinSlotSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pc = pcs(:one)
    @pc.update!(status: :online)

    @coin_slot = coin_slots(:one)
    CoinSlot.where.not(id: @coin_slot.id).update_all(status: CoinSlot.statuses[:offline])
    @coin_slot.update!(status: :online)

    @coin_slot.coin_slot_sessions.update_all(status: CoinSlotSession.statuses[:stopped])
    clear_enqueued_jobs
  end

  test "signed pc starts an online coin slot session" do
    path = winform_pc_coin_slot_sessions_path(@pc)
    headers = signed_headers(@pc, method: "POST", path: path)

    suppress_changed_action do
      assert_difference("CoinSlotSession.count", 1) do
        assert_difference("Command.count", 1) do
          post path, headers: headers
        end
      end
    end

    coin_slot_session = CoinSlotSession.order(:id).last

    assert_redirected_to winform_pc_path(@pc.device_id)
    assert_equal @pc, coin_slot_session.pc
    assert_equal @coin_slot, coin_slot_session.coin_slot
    assert coin_slot_session.active?
    assert @coin_slot.reload.active?
    assert_equal "enable", @coin_slot.commands.order(:id).last.commandable.action
  end

  test "signed pc is redirected when no online coin slot is available" do
    CoinSlot.update_all(status: CoinSlot.statuses[:offline])

    path = winform_pc_coin_slot_sessions_path(@pc)
    headers = signed_headers(@pc, method: "POST", path: path)

    assert_no_difference("CoinSlotSession.count") do
      post path, headers: headers
    end

    assert_redirected_to winform_pc_path(@pc.device_id)
    assert_equal "No coin slot found!", flash[:alert]
  end

  test "signed pc cancels active coin slot session" do
    coin_slot_session = coin_slot_sessions(:one)
    coin_slot_session.update!(
      pc: @pc,
      coin_slot: @coin_slot,
      status: :active,
      ended_at: nil
    )
    @coin_slot.update!(status: :active)

    path = cancel_winform_pc_coin_slot_sessions_path(@pc)
    headers = signed_headers(@pc, method: "PATCH", path: path)

    suppress_changed_action do
      assert_difference("Command.count", 1) do
        patch path, headers: headers
      end
    end

    assert_redirected_to winform_pc_path(@pc.device_id)
    assert coin_slot_session.reload.stopped?
    assert coin_slot_session.ended?
    assert @coin_slot.reload.online?
    assert_equal "disable", @coin_slot.commands.order(:id).last.commandable.action
  end

  test "signed pc is redirected when cancelling without active coin slot session" do
    @pc.coin_slot_sessions.update_all(status: CoinSlotSession.statuses[:stopped])

    path = cancel_winform_pc_coin_slot_sessions_path(@pc)
    headers = signed_headers(@pc, method: "PATCH", path: path)

    assert_no_difference("Command.count") do
      patch path, headers: headers
    end

    assert_redirected_to winform_pc_path(@pc.device_id)
    assert_equal "No coin slot session active found!", flash[:alert]
  end

  private

  def suppress_changed_action
    CoinSlotSessions::ChangedAction.stub(:call, ->(*) { }) do
      yield
    end
  end
end
