require "test_helper"

class Pcs::ShutdownScheduleJobTest < ActiveJob::TestCase
  test "schedules shutdown with configured wait time" do
    pc = pcs(:one)
    # Ensure the setting is present (default is 300 seconds)
    Setting.set("pc_shutdown_wait_time", 300, "duration")

    expected_time = 300.seconds.from_now
    assert_enqueued_with(job: Pcs::ShutdownScheduleJob, args: [ pc.id ], at: expected_time) do
      pc.send(:schedule_shutdown)
    end
  end
end
