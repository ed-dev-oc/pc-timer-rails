require "test_helper"

class PcTest < ActiveSupport::TestCase
  setup do
    @pc = pcs(:one)
  end

  test "valid fixture is valid" do
    assert @pc.valid?
  end

  test "authorized_status? returns true for authorized statuses" do
    Pc::AUTHORIZED_STATUSES.each do |status|
      @pc.update!(status: status)
      assert @pc.authorized_status?, "#{status} should be authorized"
    end
  end

  test "authorized_status? returns false for unauthorized statuses" do
    unauthorized_statuses = Pc.statuses.keys.map(&:to_sym) - Pc::AUTHORIZED_STATUSES

    unauthorized_statuses.each do |status|
      @pc.update_columns(status: Pc.statuses[status])
      assert_not @pc.authorized_status?, "#{status} should not be authorized"
    end
  end

  test "start_session! raises when there are no unused coin transactions" do
    @pc.coin_transactions.destroy_all

    assert_raises(Pc::NoInsertedCoinsError) do
      @pc.start_session!
    end
  end

  test "start_session! creates an active session and activates the PC" do
    coin_transaction = coin_transactions(:one)
    coin_transaction.update!(pc: @pc, status: :unused)

    assert_difference("PcSession.count", 1) do
      assert_enqueued_with(job: Pcs::SessionExpirationJob) do
        @pc.start_session!
      end
    end

    @pc.reload

    assert @pc.active?
    assert @pc.active_session.present?
    assert_equal "active", @pc.active_session.status
    assert_equal "used", coin_transaction.reload.status
  end

  test "start_manual_session! creates an active session without coins" do
    @pc.coin_transactions.destroy_all

    attributes = {
      pc: @pc,
      total_minutes_purchased: 30,
      total_amount: 0
    }

    assert_difference("PcSession.count", 1) do
      assert_enqueued_with(job: Pcs::SessionExpirationJob) do
        @pc.start_manual_session!(attributes)
      end
    end

    @pc.reload

    assert @pc.active?
    assert @pc.active_session.present?
    assert_equal 30, @pc.active_session.total_minutes_purchased
    assert_equal 0, @pc.active_session.total_amount
  end

  test "extend_session! extends the active session using unused coins" do
    Setting.set("minutes_per_credit", 2, "integer")

    session = pc_sessions(:one)
    session.update!(
      pc: @pc,
      status: :active,
      expires_at: 10.minutes.from_now
    )

    coin_transaction = coin_transactions(:one)
    coin_transaction.update!(
      pc: @pc,
      status: :unused,
      peso_amount: 5,
      minutes_granted: 10
    )

    original_expiration = session.reload.expires_at

    assert_enqueued_with(job: Pcs::SessionExpirationJob) do
      @pc.extend_session!(session)
    end

    session.reload
    @pc.reload

    assert_equal "active", session.status
    assert_equal original_expiration + 10.minutes, session.expires_at
    assert_equal 11, session.total_minutes_purchased
    assert_equal "used", coin_transaction.reload.status
    assert @pc.active?
  end

  test "extend_session! raises when there are no unused coin transactions" do
    session = pc_sessions(:one)
    session.update!(
      pc: @pc,
      status: :active,
      expires_at: 10.minutes.from_now
    )

    @pc.coin_transactions.destroy_all

    assert_raises(Pc::NoInsertedCoinsError) do
      @pc.extend_session!(session)
    end
  end

  test "stop_session! stops the session and puts the PC online" do
    session = pc_sessions(:one)
    session.update!(
      pc: @pc,
      status: :active,
      started_at: 10.minutes.ago,
      expires_at: 10.minutes.from_now
    )

    @pc.update!(status: :active)

    assert_enqueued_with(job: Pcs::ShutdownScheduleJob) do
      @pc.stop_session!(session)
    end

    session.reload
    @pc.reload

    assert session.ended?
    assert session.stopped?
    assert @pc.online?
  end

  test "signin! sets PC to online when there is no active session" do
    @pc.update!(status: :offline)

    @pc.signin!

    @pc.reload

    assert @pc.online?
  end

  test "signin! sets PC to active when an active session exists" do
    session = pc_sessions(:one)
    session.update!(pc: @pc, status: :active)

    @pc.update!(status: :offline)

    @pc.signin!

    assert @pc.reload.active?
  end

  test "signin! preserves disabled kiosk status" do
    @pc.update_columns(status: Pc.statuses[:disabled_kiosk])

    @pc.signin!

    assert @pc.reload.disabled_kiosk?
  end

  test "signout! sets PC to offline" do
    @pc.update!(status: :online)

    @pc.signout!

    @pc.reload

    assert @pc.offline?
  end

  test "receive_heartbeat! updates device attributes" do
    seen_at = Time.current.change(usec: 0)

    @pc.receive_heartbeat!(
      status: :online,
      ip_address: "192.168.1.123",
      mac_address: "AA:BB:CC:DD:EE:12",
      last_seen_at: seen_at
    )

    @pc.reload

    assert @pc.online?
    assert_equal "192.168.1.123", @pc.ip_address
    assert_equal "AA:BB:CC:DD:EE:12", @pc.mac_address
    assert_equal seen_at, @pc.last_seen_at
  end

  test "active_session_json returns nil without active session" do
    @pc.pc_sessions.update_all(status: PcSession.statuses[:stopped])

    assert_nil @pc.reload.active_session_json
  end

  test "active_session_json returns active session details" do
    expires_at = 20.minutes.from_now.change(usec: 0)
    session = pc_sessions(:one)
    session.update!(
      pc: @pc,
      status: :active,
      started_at: Time.current,
      expires_at: expires_at
    )

    session_json = @pc.reload.active_session_json

    assert_equal session.public_uid, session_json[:id]
    assert_equal "active", session_json[:status]
    assert_equal expires_at.utc, session_json[:expires_at_utc]
  end

  test "immutable status cannot change to ordinary status" do
    @pc.update_columns(status: Pc.statuses[:archived])

    @pc.update!(status: :online)

    assert @pc.reload.archived?
  end

  test "immutable status can change through explicit restoration status" do
    @pc.update_columns(status: Pc.statuses[:archived])

    @pc.update!(status: :unarchived)

    assert @pc.reload.unarchived?
  end

  test "disabled_kiosk status cannot change to ordinary status" do
    @pc.update_columns(status: Pc.statuses[:disabled_kiosk])

    @pc.update!(status: :online)

    assert @pc.reload.disabled_kiosk?
  end

  test "disabled_kiosk can be restored via enabled_kiosk" do
    @pc.update_columns(status: Pc.statuses[:disabled_kiosk])

    @pc.update!(status: :enabled_kiosk)

    assert @pc.reload.enabled_kiosk?
  end

  test "shutdown! queues shutdown command and puts PC offline" do
    @pc.update!(status: :online)

    assert_difference("PcCommandLog.count", 1) do
      assert_enqueued_with(job: Pcs::CommandJob) do
        @pc.shutdown!
      end
    end

    @pc.reload

    assert @pc.offline?
    assert_equal "shutdown", @pc.pc_command_logs.order(:id).last.command
  end

  test "restart! queues restart command and puts PC offline" do
    @pc.update!(status: :online)

    assert_difference("PcCommandLog.count", 1) do
      assert_enqueued_with(job: Pcs::CommandJob) do
        @pc.restart!
      end
    end

    @pc.reload

    assert @pc.offline?
    assert_equal "restart", @pc.pc_command_logs.order(:id).last.command
  end

  test "register! creates a PC" do
    attributes = {
      name: "Registered PC",
      device_id: "registered-pc",
      ip_address: "192.168.1.50",
      mac_address: "AA:BB:CC:DD:EE:FF",
      status: :online
    }

    assert_difference("Pc.count", 1) do
      pc = Pc.register!(attributes)

      assert_equal "registered-pc", pc.device_id
      assert_equal "Registered PC", pc.name
      assert pc.secret.present?
    end
  end

  test "register! updates an existing PC by device_id" do
    attributes = {
      device_id: @pc.device_id,
      name: "Updated PC",
      ip_address: "192.168.1.99",
      mac_address: "AA:BB:CC:DD:EE:99",
      status: :online
    }

    assert_no_difference("Pc.count") do
      Pc.register!(attributes)
    end

    @pc.reload

    assert_equal "Updated PC", @pc.name
    assert_equal "192.168.1.99", @pc.ip_address
    assert_equal "AA:BB:CC:DD:EE:99", @pc.mac_address
  end
end
