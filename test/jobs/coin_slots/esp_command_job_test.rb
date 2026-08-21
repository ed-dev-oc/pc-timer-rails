require "test_helper"

class CoinSlots::EspCommandJobTest < ActiveJob::TestCase
  class FakeEspClient
    attr_reader :coin_slot, :calls
    attr_accessor :error

    def initialize(coin_slot)
      @coin_slot = coin_slot
      @calls = []
    end

    def enable(coin_slot_session)
      raise error if error
      calls << [ :enable, coin_slot_session ]
    end

    def disable(coin_slot_session)
      raise error if error
      calls << [ :disable, coin_slot_session ]
    end

    def restart
      raise error if error
      calls << [ :restart ]
    end
  end

  setup do
    @coin_slot = coin_slots(:one)
    @pc = pcs(:one)
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "enable command sends active session to ESP and marks log successful" do
    session = coin_slot_sessions(:one)
    session.update_columns(
      coin_slot_id: @coin_slot.id,
      pc_id: @pc.id,
      status: CoinSlotSession.statuses[:active],
      ended_at: nil,
      expires_at: 10.minutes.from_now
    )
    @coin_slot.reload
    log = create_command_log(:enable)
    client = FakeEspClient.new(@coin_slot)

    freeze_time do
      stub_coin_slot_agent(client) do
        CoinSlots::EspCommandJob.perform_now(log.id)
      end

      log.reload

      assert log.status_success?
      assert_equal Time.current, log.executed_at
    end

    assert_equal [ [ :enable, session ] ], client.calls
  end

  test "disable command sends provided session to ESP and marks log successful" do
    session = coin_slot_sessions(:one)
    session.update_columns(
      coin_slot_id: @coin_slot.id,
      pc_id: @pc.id,
      status: CoinSlotSession.statuses[:stopped],
      ended_at: Time.current,
      expires_at: 1.minute.ago
    )
    log = create_command_log(:disable)
    client = FakeEspClient.new(@coin_slot)

    freeze_time do
      stub_coin_slot_agent(client) do
        CoinSlots::EspCommandJob.perform_now(log.id, session.id)
      end

      log.reload

      assert log.status_success?
      assert_equal Time.current, log.executed_at
    end

    assert_equal [ [ :disable, session ] ], client.calls
  end

  test "disable command requires coin slot session id" do
    log = create_command_log(:disable)
    client = FakeEspClient.new(@coin_slot)

    assert_raises(ArgumentError) do
      stub_coin_slot_agent(client) do
        CoinSlots::EspCommandJob.perform_now(log.id)
      end
    end

    log.reload

    assert log.status_failed?
    assert_equal "coin_slot_session_id is required for disable command", log.error_message
    assert_not_nil log.executed_at
    assert_empty client.calls
  end

  test "restart command sends restart to ESP and marks log successful" do
    log = create_command_log(:restart)
    client = FakeEspClient.new(@coin_slot)

    freeze_time do
      stub_coin_slot_agent(client) do
        CoinSlots::EspCommandJob.perform_now(log.id)
      end

      log.reload

      assert log.status_success?
      assert_equal Time.current, log.executed_at
    end

    assert_equal [ [ :restart ] ], client.calls
  end

  test "connection failure retries and leaves command log pending" do
    log = create_command_log(:restart)
    client = FakeEspClient.new(@coin_slot)
    client.error = Faraday::ConnectionFailed.new("ESP connection failed")

    assert_enqueued_with(job: CoinSlots::EspCommandJob, args: [ log.id ]) do
      stub_coin_slot_agent(client) do
        CoinSlots::EspCommandJob.perform_now(log.id)
      end
    end

    log.reload
    assert log.status_pending?
    assert_nil log.error_message
    assert_nil log.executed_at
    assert_empty client.calls
  end

  private

    def stub_coin_slot_agent(client)
      original = CoinSlot.instance_method(:agent)
      CoinSlot.define_method(:agent) { client }
      yield
    ensure
      CoinSlot.define_method(:agent, original)
    end

    def create_command_log(command)
      @coin_slot.esp_command_logs.create!(
        command: command,
        status: :pending,
        sent_at: Time.current
      ).tap do
        clear_enqueued_jobs
      end
    end
end
