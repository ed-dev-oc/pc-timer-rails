require "test_helper"

class PcSessionTest < ActiveSupport::TestCase
  setup do
    @pc = pcs(:one)
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "manual session does not require minimum coin credit" do
    pc_session = PcSession.new(
      pc: @pc,
      total_minutes_purchased: 30,
      total_amount: 0,
      started_at: Time.current,
      expires_at: 30.minutes.from_now
    )

    assert pc_session.valid?
  end

  test "coin funded session requires unused coin total to meet minimum credit" do
    @pc.coin_transactions.destroy_all
    Setting.set("minimum_credit", 5, "integer")

    @pc.coin_transactions.create!(
      coin_slot: coin_slots(:one),
      transaction_uid: "pc-session-minimum-credit",
      peso_amount: 1
    )

    pc_session = PcSession.new(
      pc: @pc,
      total_minutes_purchased: 30,
      total_amount: 1,
      started_at: Time.current,
      expires_at: 30.minutes.from_now
    )

    assert_not pc_session.valid?
    assert_includes pc_session.errors[:base], "Please insert ₱5 or more to play!"
  end

  test "start! creates a coin funded session from unused transactions" do
    @pc.coin_transactions.destroy_all
    Setting.set("minimum_credit", 5, "integer")
    Setting.set("minutes_per_credit", 2, "integer")

    first_credit = @pc.coin_transactions.create!(
      coin_slot: coin_slots(:one),
      transaction_uid: "pc-session-start-credit-one",
      peso_amount: 5
    )
    second_credit = @pc.coin_transactions.create!(
      coin_slot: coin_slots(:one),
      transaction_uid: "pc-session-start-credit-two",
      peso_amount: 10
    )

    freeze_time do
      session = nil

      assert_difference("PcSession.count", 1) do
        assert_enqueued_with(job: Pcs::SessionExpirationJob) do
          session = PcSession.start!(@pc, @pc.coin_transactions.unused)
        end
      end

      assert_equal @pc, session.pc
      assert_equal "active", session.status
      assert_equal 30, session.total_minutes_purchased
      assert_equal 15, session.total_amount
      assert_equal Time.current, session.started_at
      assert_equal 30.minutes.from_now, session.expires_at
    end

    assert_equal "used", first_credit.reload.status
    assert_equal "used", second_credit.reload.status
  end

  test "start_manual! creates a manual session and schedules expiration" do
    @pc.coin_transactions.destroy_all

    freeze_time do
      session = nil

      assert_difference("PcSession.count", 1) do
        assert_enqueued_with(job: Pcs::SessionExpirationJob) do
          session = PcSession.start_manual!(
            pc: @pc,
            total_minutes_purchased: 45,
            total_amount: 0
          )
        end
      end

      assert_equal @pc, session.pc
      assert_equal "active", session.status
      assert_equal 45, session.total_minutes_purchased
      assert_equal 0, session.total_amount
      assert_equal Time.current, session.started_at
      assert_equal 45.minutes.from_now, session.expires_at
    end
  end

  test "cannot create a second active session for the same PC" do
    pc_sessions(:one).update!(
      pc: @pc,
      status: :active,
      started_at: 10.minutes.ago,
      expires_at: 20.minutes.from_now
    )

    duplicate_session = PcSession.new(
      pc: @pc,
      total_minutes_purchased: 30,
      total_amount: 0,
      started_at: Time.current,
      expires_at: 30.minutes.from_now
    )

    assert_not duplicate_session.valid?
    assert_includes duplicate_session.errors[:base], "This PC already have active session!"
  end

  test "extend! adds unused transaction totals and schedules expiration" do
    @pc.coin_transactions.destroy_all
    Setting.set("minutes_per_credit", 2, "integer")

    session = pc_sessions(:one)
    session.update!(
      pc: @pc,
      status: :active,
      total_minutes_purchased: 30,
      total_amount: 15,
      expires_at: 30.minutes.from_now
    )
    credit = @pc.coin_transactions.create!(
      coin_slot: coin_slots(:one),
      transaction_uid: "pc-session-extend-credit",
      peso_amount: 5
    )
    original_expiration = session.reload.expires_at

    assert_enqueued_with(job: Pcs::SessionExpirationJob) do
      session.extend!(@pc.coin_transactions.unused)
    end

    session.reload

    assert_equal "active", session.status
    assert_equal 40, session.total_minutes_purchased
    assert_equal 20, session.total_amount
    assert_equal original_expiration + 10.minutes, session.expires_at
    assert_equal "used", credit.reload.status
  end

  test "schedule_expiration enqueues expiration job for expires_at" do
    session = pc_sessions(:one)
    session.update!(
      pc: @pc,
      status: :active,
      expires_at: 15.minutes.from_now
    )

    assert_enqueued_with(job: Pcs::SessionExpirationJob, at: session.expires_at) do
      session.schedule_expiration
    end
  end

  test "total_remaining_seconds returns correct value for active session" do
    session = pc_sessions(:one)
    session.update!(expires_at: 1.hour.from_now, status: :active)
    remaining = session.total_remaining_seconds
    assert_in_delta 3600, remaining, 5
  end

  test "total_remaining_seconds returns zero when session ended" do
    session = pc_sessions(:one)
    session.update!(status: :stopped)
    assert_equal 0, session.total_remaining_seconds
  end

  test "total_remaining_seconds returns zero when expired" do
    session = pc_sessions(:one)
    session.update!(expires_at: 1.hour.ago, status: :active)
    assert_equal 0, session.total_remaining_seconds
  end

  test "total_duration_formatted returns hh mm ss duration" do
    session = pc_sessions(:one)
    session.update!(total_minutes_purchased: 125)

    assert_equal "02:05:00", session.total_duration_formatted
  end

  test "total_purchased_duration_ms returns purchased duration in milliseconds" do
    session = pc_sessions(:one)
    session.update!(total_minutes_purchased: 30)

    assert_equal 1_800_000, session.total_purchased_duration_ms
  end

  test "stop! sets ended_at timestamp" do
    # Create a session manually to control timestamps
    session = PcSession.create!(
      pc: @pc,
      total_minutes_purchased: 30,
      total_amount: 0,
      started_at: 1.hour.ago,
      expires_at: 30.minutes.from_now,
      status: :active
    )

    freeze_time do
      current = Time.current
      session.stop!
      session.reload
      assert_equal "stopped", session.status
      assert_in_delta current.to_i, session.ended_at.to_i, 1
    end
  end

  test "stop! records total minutes used" do
    session = PcSession.create!(
      pc: @pc,
      total_minutes_purchased: 90,
      total_amount: 0,
      started_at: 61.minutes.ago,
      expires_at: 30.minutes.from_now,
      status: :active
    )

    freeze_time do
      session.stop!

      assert_equal 61, session.reload.total_minutes_used
    end
  end
end
