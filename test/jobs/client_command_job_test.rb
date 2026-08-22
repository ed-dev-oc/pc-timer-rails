require "test_helper"

class ClientCommandJobTest < ActiveJob::TestCase
  setup do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "perform marks command successful after execute" do
    command = commands(:pc_unlock)
    command.update!(status: :pending, executed_at: nil, error_message: nil)

    Command.stub(:find, command) do
      command.stub(:execute!, true) do
      freeze_time do
        ClientCommandJob.perform_now(command.id)
        command.reload

        assert command.true_success?
        assert_equal Time.current, command.executed_at
        assert_nil command.error_message
      end
      end
    end
  end
end
