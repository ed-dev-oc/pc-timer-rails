require "test_helper"

class Pcs::CommandJobTest < ActiveJob::TestCase
  class FakeAgentClient
    attr_reader :pc, :calls
    attr_accessor :error

    def initialize(pc)
      @pc = pc
      @calls = []
    end

    def lock
      call(:lock)
    end

    def unlock
      call(:unlock)
    end

    def restart
      call(:restart)
    end

    def shutdown
      call(:shutdown)
    end

    private

      def call(command)
        raise error if error

        calls << command
      end
  end

  setup do
    @pc = pcs(:one)
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "lock command sends lock to PC agent and marks log successful" do
    assert_command_dispatch(:lock)
  end

  test "unlock command sends unlock to PC agent and marks log successful" do
    assert_command_dispatch(:unlock)
  end

  test "restart command sends restart to PC agent and marks log successful" do
    assert_command_dispatch(:restart)
  end

  test "shutdown command sends shutdown to PC agent and marks log successful" do
    assert_command_dispatch(:shutdown)
  end

  test "client connection failure retries and leaves command log pending" do
    log = create_command_log(:lock)
    client = FakeAgentClient.new(@pc)
    client.error = Faraday::ConnectionFailed.new("HTTP 500")

    assert_enqueued_with(job: Pcs::CommandJob, args: [ log.id ]) do
      stub_pc_agent(client) do
        Pcs::CommandJob.perform_now(log.id)
      end
    end

    log.reload

    assert log.status_pending?
    assert_nil log.error_message
    assert_nil log.executed_at
    assert_empty client.calls
  end

  private

  def assert_command_dispatch(command)
    log = create_command_log(command)
    client = FakeAgentClient.new(@pc)

    freeze_time do
        stub_pc_agent(client) do
          Pcs::CommandJob.perform_now(log.id)
        end

        log.reload

        assert log.status_success?
        assert_equal Time.current, log.executed_at
      end

      assert_equal [ command ], client.calls
    end

    def stub_pc_agent(client)
      original = Pc.instance_method(:agent)
      Pc.define_method(:agent) { client }
      yield
    ensure
      Pc.define_method(:agent, original)
    end

    def create_command_log(command)
      @pc.pc_command_logs.create!(
        command: command,
        status: :pending,
        sent_at: Time.current
      ).tap do
        clear_enqueued_jobs
      end
    end
end
