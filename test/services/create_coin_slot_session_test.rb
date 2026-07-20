require "test_helper"

class CreateCoinSlotSessionTest < ActiveSupport::TestCase
  test "successful creation creates session, updates coin slot status, enqueues job and creates esp enable log" do
    coin_slot = coin_slots(:one)
    pc = pcs(:one)

    assert_enqueued_with(job: CoinSlotSessionTimerJob) do
      result = CreateCoinSlotSession.call(pc, coin_slot)
      assert result.success?
      session = result.value
      assert_instance_of CoinSlotSession, session
      assert_equal "active", session.status
      coin_slot.reload
      assert_equal "active_session", coin_slot.status
      # ESP enable command log created
      # Fixture already includes one enable log, service adds another
      assert_equal 2, coin_slot.esp_command_logs.count
      log = coin_slot.esp_command_logs.last
      assert_equal "enable", log.command
      assert_equal "pending", log.status
    end
  end

  test "failure when record invalid returns failure result" do
    # Pass nil pc to trigger validation error on CoinSlotSession creation
    coin_slot = coin_slots(:one)
    result = CreateCoinSlotSession.call(nil, coin_slot)
    refute result.success?
    assert_match /Pc must exist/, result.error
  end
end
