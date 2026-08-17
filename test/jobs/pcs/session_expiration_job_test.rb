require "test_helper"

class Pcs::SessionExpirationJobTest < ActiveJob::TestCase
  setup do
    @pc = pcs(:one)
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "missing session is ignored" do
    assert_nothing_raised do
      Pcs::SessionExpirationJob.perform_now(-1)
    end
  end

  test "ended session is ignored" do
    session = pc_sessions(:one)
    session.update_columns(
      pc_id: @pc.id,
      status: PcSession.statuses[:stopped],
      ended_at: Time.current,
      expires_at: 1.minute.ago
    )

    assert_no_difference("PcCommandLog.count") do
      PcSessions::BroadcastService.stub(:call, ->(*) { flunk "broadcast service should not be called" }) do
        Pcs::SessionExpirationJob.perform_now(session.id)
      end
    end
  end

  test "unexpired active session is ignored" do
    session = pc_sessions(:one)
    session.update_columns(
      pc_id: @pc.id,
      status: PcSession.statuses[:active],
      ended_at: nil,
      expires_at: 10.minutes.from_now
    )

    assert_no_difference("PcCommandLog.count") do
      PcSessions::BroadcastService.stub(:call, ->(*) { flunk "broadcast service should not be called" }) do
        Pcs::SessionExpirationJob.perform_now(session.id)
      end
    end

    assert session.reload.active?
  end

  test "expired active session is stopped and broadcasts changes" do
    session = pc_sessions(:one)
    session.update_columns(
      pc_id: @pc.id,
      status: PcSession.statuses[:active],
      ended_at: nil,
      started_at: 30.minutes.ago,
      expires_at: 1.minute.ago
    )
    @pc.update!(status: :active)

    broadcasted_pcs = []

    assert_difference("PcCommandLog.count", 1) do
      assert_enqueued_with(job: Pcs::CommandJob) do
        assert_enqueued_with(job: Pcs::ShutdownScheduleJob) do
          PcSessions::BroadcastService.stub(:call, ->(pc) { broadcasted_pcs << pc }) do
            Pcs::SessionExpirationJob.perform_now(session.id)
          end
        end
      end
    end

    session.reload
    @pc.reload

    assert session.stopped?
    assert session.ended?
    assert_equal 30, session.total_minutes_used
    assert @pc.online?
    assert_equal [ @pc ], broadcasted_pcs
    assert_equal "lock", @pc.pc_command_logs.order(:id).last.command
  end
end
