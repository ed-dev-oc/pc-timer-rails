require "test_helper"

class CommandTest < ActiveSupport::TestCase
  setup do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "pc command fixture is valid" do
    command = commands(:pc_unlock)

    assert command.valid?
    assert_instance_of Command, command
    assert command.true_sent?
    assert_equal "unlock", command.action
    assert_instance_of PcCommand, command.commandable
  end

  test "coin slot command fixture is valid" do
    command = commands(:coin_slot_disable)

    assert command.valid?
    assert_instance_of Command, command
    assert command.true_sent?
    assert_equal "disable", command.action
    assert_instance_of CoinSlotCommand, command.commandable
  end

  test "status enum exposes command lifecycle states" do
    command = commands(:pc_unlock)

    command.true_pending!
    assert command.true_pending?

    command.true_success!
    assert command.true_success?

    command.true_failed!
    assert command.true_failed?
  end

  test "pc command requires pc" do
    pc_command = PcCommand.new(action: :lock)

    assert_not pc_command.valid?
    assert_includes pc_command.errors[:pc], "must exist"
  end

  test "coin slot command requires coin slot" do
    coin_slot_command = CoinSlotCommand.new(action: :enable)

    assert_not coin_slot_command.valid?
    assert_includes coin_slot_command.errors[:coin_slot], "must exist"
  end

  test "creating a pc command schedules client command job" do
    command = nil

    assert_enqueued_with(job: ClientCommandJob) do
      commandable = pcs(:one).pc_commands.create!(action: :lock)
      command = Command.create!(
        commandable: commandable,
        sent_at: Time.current
      )
    end

    assert command.persisted?
  end

  test "creating a coin slot command schedules client command job" do
    command = nil

    assert_enqueued_with(job: ClientCommandJob) do
      commandable = coin_slots(:one).coin_slot_commands.create!(
        action: :disable,
        coin_slot_session: coin_slot_sessions(:one)
      )
      command = Command.create!(
        commandable: commandable,
        sent_at: Time.current
      )
    end

    assert command.persisted?
  end
end
