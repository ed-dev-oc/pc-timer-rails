require "test_helper"

class CoinSlots::SessionTimerJobTest < ActiveJob::TestCase
  setup do
    @coin_slot = coin_slots(:one)
    @pc = pcs(:one)
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "missing session is ignored" do
    assert_nothing_raised do
      CoinSlots::SessionTimerJob.perform_now(-1)
    end
  end

  test "ended session is ignored" do
    session = coin_slot_sessions(:one)
    session.update_columns(
      coin_slot_id: @coin_slot.id,
      pc_id: @pc.id,
      status: CoinSlotSession.statuses[:stopped],
      ended_at: Time.current,
      expires_at: 1.minute.ago
    )

    assert_no_difference("Command.count") do
      CoinSlotSessions::ChangedAction.stub(:call, ->(*) { flunk "changed action should not be called" }) do
        Pcs::SessionControlsChanged.stub(:call, ->(*) { flunk "session controls should not be called" }) do
          CoinSlots::SessionTimerJob.perform_now(session.id)
        end
      end
    end
  end

  test "unexpired active session is ignored" do
    session = coin_slot_sessions(:one)
    session.update_columns(
      coin_slot_id: @coin_slot.id,
      pc_id: @pc.id,
      status: CoinSlotSession.statuses[:active],
      ended_at: nil,
      expires_at: 10.minutes.from_now
    )

    assert_no_difference("Command.count") do
      CoinSlotSessions::ChangedAction.stub(:call, ->(*) { flunk "changed action should not be called" }) do
        Pcs::SessionControlsChanged.stub(:call, ->(*) { flunk "session controls should not be called" }) do
          CoinSlots::SessionTimerJob.perform_now(session.id)
        end
      end
    end

    assert session.reload.active?
  end

  test "expired active session is stopped and broadcasts changes" do
    session = coin_slot_sessions(:one)
    session.update_columns(
      coin_slot_id: @coin_slot.id,
      pc_id: @pc.id,
      status: CoinSlotSession.statuses[:active],
      ended_at: nil,
      started_at: 10.minutes.ago,
      expires_at: 1.minute.ago
    )
    @coin_slot.update!(status: :active)

    changed_sessions = []
    changed_pcs = []

    assert_difference("Command.count", 1) do
      assert_enqueued_with(job: ClientCommandJob) do
        CoinSlotSessions::ChangedAction.stub(:call, ->(changed_session) { changed_sessions << changed_session }) do
          Pcs::SessionControlsChanged.stub(:call, ->(changed_pc) { changed_pcs << changed_pc }) do
            CoinSlots::SessionTimerJob.perform_now(session.id)
          end
        end
      end
    end

    session.reload
    @coin_slot.reload

    assert session.stopped?
    assert session.ended?
    assert @coin_slot.online?
    assert_equal [ session ], changed_sessions
    assert_equal [ @pc ], changed_pcs
    assert_equal "disable", @coin_slot.commands.order(:id).last.action
  end
end
