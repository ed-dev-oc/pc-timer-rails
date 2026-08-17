require "test_helper"

class CommandLogTest < ActiveSupport::TestCase
  setup do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "pc command log fixture is valid" do
    command_log = command_logs(:one)

    assert command_log.valid?
    assert_instance_of PcCommandLog, command_log
    assert command_log.status_sent?
    assert command_log.command_unlock?
  end

  test "esp command log fixture is valid" do
    command_log = command_logs(:two)

    assert command_log.valid?
    assert_instance_of EspCommandLog, command_log
    assert command_log.status_sent?
    assert command_log.command_disable?
  end

  test "status enum exposes command lifecycle states" do
    command_log = command_logs(:one)

    command_log.status_pending!
    assert command_log.status_pending?

    command_log.status_success!
    assert command_log.status_success?

    command_log.status_failed!
    assert command_log.status_failed?
  end

  test "pc command log requires pc" do
    command_log = PcCommandLog.new(
      command: :lock,
      status: :pending,
      sent_at: Time.current
    )

    assert_not command_log.valid?
    assert_includes command_log.errors[:pc], "must exist"
  end

  test "pc command log enqueues pc command job after create" do
    command_log = nil

    assert_enqueued_with(job: Pcs::CommandJob) do
      command_log = pcs(:one).pc_command_logs.create!(
        command: :lock,
        status: :pending,
        sent_at: Time.current
      )
    end

    assert command_log.persisted?
  end

  test "esp command log requires coin slot" do
    command_log = EspCommandLog.new(
      command: :enable,
      status: :pending,
      sent_at: Time.current
    )

    assert_not command_log.valid?
    assert_includes command_log.errors[:coin_slot], "must exist"
  end

  test "esp command log enqueues esp command job after create" do
    command_log = nil

    assert_enqueued_with(job: CoinSlots::EspCommandJob) do
      command_log = coin_slots(:one).esp_command_logs.create!(
        command: :enable,
        status: :pending,
        sent_at: Time.current
      )
    end

    assert command_log.persisted?
  end
end
