require "test_helper"

class Pcs::ShutdownScheduleJobTest < ActiveJob::TestCase
  setup do
    @pc = pcs(:one)
    @pc.pc_sessions.update_all(status: PcSession.statuses[:stopped])
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "schedules shutdown with configured wait time" do
    Setting.set("pc_shutdown_wait_time", 300, "duration")

    expected_time = 300.seconds.from_now
    assert_enqueued_with(job: Pcs::ShutdownScheduleJob, args: [ @pc.id ], at: expected_time) do
      @pc.send(:schedule_shutdown)
    end
  end

  test "online PC with no active session is shut down" do
    @pc.update!(status: :online)

    assert_difference("PcCommandLog.count", 1) do
      assert_enqueued_with(job: Pcs::CommandJob) do
        Pcs::ShutdownScheduleJob.perform_now(@pc.id)
      end
    end

    assert @pc.reload.offline?
    assert_equal "shutdown", @pc.pc_command_logs.order(:id).last.command
  end

  test "PC with an active session is not shut down" do
    pc_sessions(:one).update!(
      pc: @pc,
      status: :active,
      started_at: 5.minutes.ago,
      expires_at: 25.minutes.from_now
    )
    @pc.update!(status: :active)

    assert_no_difference("PcCommandLog.count") do
      Pcs::ShutdownScheduleJob.perform_now(@pc.id)
    end

    assert @pc.reload.active?
  end

  test "disabled_kiosk PC is not shut down" do
    @pc.update_columns(status: Pc.statuses[:disabled_kiosk])

    assert_no_difference("PcCommandLog.count") do
      Pcs::ShutdownScheduleJob.perform_now(@pc.id)
    end

    assert @pc.reload.disabled_kiosk?
  end

  test "archived PC is not shut down" do
    @pc.update_columns(status: Pc.statuses[:archived])

    assert_no_difference("PcCommandLog.count") do
      Pcs::ShutdownScheduleJob.perform_now(@pc.id)
    end

    assert @pc.reload.archived?
  end
end
