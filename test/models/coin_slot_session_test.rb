require "test_helper"

class CoinSlotSessionTest < ActiveSupport::TestCase
  setup do
    @coin_slot = coin_slots(:one)
    @pc = pcs(:one)
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "valid fixture is valid" do
    session = coin_slot_sessions(:one)
    assert session.valid?
  end

  test "start! creates active session with timestamps and enqueues expiration job" do
    session = nil

    assert_difference("CoinSlotSession.count", 1) do
      assert_enqueued_with(job: CoinSlots::SessionTimerJob) do
        session = CoinSlotSession.start!(@coin_slot, @pc)
      end
    end

    assert_equal @coin_slot, session.coin_slot
    assert_equal @pc, session.pc
    assert_equal "active", session.status
    assert_not_nil session.started_at
    assert_not_nil session.expires_at
    expected_duration = Setting.duration("coin_slot_session_duration").seconds
    assert_in_delta expected_duration, (session.expires_at - session.started_at), 1
  end

  test "schedule_expiration enqueues timer job for expires_at" do
    session = coin_slot_sessions(:one)
    session.update_columns(
      coin_slot_id: @coin_slot.id,
      pc_id: @pc.id,
      status: CoinSlotSession.statuses[:active],
      started_at: 5.minutes.ago,
      expires_at: 10.minutes.from_now
    )

    assert_enqueued_with(job: CoinSlots::SessionTimerJob, at: session.expires_at) do
      session.schedule_expiration
    end
  end

  test "status validation only allows active on create" do
    session = CoinSlotSession.new(coin_slot: @coin_slot, pc: @pc)

    session.status = :stopped
    assert_not session.valid?

    session.status = :active
    assert session.valid?
  end

  test "cannot create second active session for same coin slot" do
    first = CoinSlotSession.start!(@coin_slot, @pc)
    assert_equal "active", first.status

    second = CoinSlotSession.new(coin_slot: @coin_slot.reload, pc: pcs(:two))
    second.status = :active

    assert_not second.valid?
    assert_includes second.errors[:base], "Coin slot currently used!"
  end

  test "start! raises when coin slot already has an active session" do
    CoinSlotSession.start!(@coin_slot, @pc)

    assert_raises(ActiveRecord::RecordInvalid) do
      CoinSlotSession.start!(@coin_slot.reload, pcs(:two))
    end
  end

  test "stop! stops session, restores coin slot online, and queues disable command" do
    @coin_slot.update!(status: :active)
    session = CoinSlotSession.start!(@coin_slot, @pc)
    started_at = 10.minutes.ago
    expires_at = 20.minutes.from_now
    session.update_columns(started_at: started_at, expires_at: expires_at)

    freeze_time do
      current = Time.current
      assert_difference("EspCommandLog.count", 1) do
        assert_enqueued_with(job: CoinSlots::EspCommandJob) do
          session.stop!
        end
      end

      session.reload

      assert_equal "stopped", session.status
      assert_equal current, session.ended_at
      assert_equal started_at.to_i, session.started_at.to_i
      assert_equal expires_at.to_i, session.expires_at.to_i
      assert @coin_slot.reload.online?
      assert_equal "disable", @coin_slot.esp_command_logs.order(:id).last.command
    end
  end

  test "lifecycle helpers reflect started expired and ended states" do
    session = coin_slot_sessions(:one)
    session.update_columns(
      started_at: 10.minutes.ago,
      expires_at: 1.minute.ago,
      ended_at: Time.current
    )

    assert session.started?
    assert session.expired?
    assert session.ended?
  end
end
