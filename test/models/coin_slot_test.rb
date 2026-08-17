require "test_helper"

class CoinSlotTest < ActiveSupport::TestCase
  setup do
    @slot = coin_slots(:one)
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "valid fixture is valid" do
    assert @slot.valid?
  end

  test "validates presence of required attributes" do
    slot = CoinSlot.new
    refute slot.valid?
    assert_includes slot.errors[:name], "can't be blank"
    assert_includes slot.errors[:mac_address], "can't be blank"
    assert_includes slot.errors[:ip_address], "can't be blank"
  end

  test "validates uniqueness of name, mac_address, ip_address, device_id" do
    duplicate = CoinSlot.new(
      name: @slot.name,
      mac_address: @slot.mac_address,
      ip_address: @slot.ip_address,
      device_id: @slot.device_id,
      status: :online
    )
    refute duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
    assert_includes duplicate.errors[:mac_address], "has already been taken"
    assert_includes duplicate.errors[:ip_address], "has already been taken"
    assert_includes duplicate.errors[:device_id], "has already been taken"
  end

  test "generates secret on create" do
    new_slot = CoinSlot.create!(
      name: "New Slot",
      mac_address: "AA:BB:CC:DD:EE:FF",
      ip_address: "192.168.1.200",
      device_id: "new-slot",
      status: :online
    )
    assert new_slot.secret.present?
    assert_match(/^sk_[0-9a-f]{64}$/, new_slot.secret)
  end

  test "authorized_status? works for authorized statuses" do
    CoinSlot::AUTHORIZED_STATUSES.each do |status|
      @slot.update!(status: status)
      assert @slot.authorized_status?, "#{status} should be authorized"
    end
  end

  test "authorized_status? returns false for unauthorized statuses" do
    unauthorized_statuses = CoinSlot.statuses.keys.map(&:to_sym) - CoinSlot::AUTHORIZED_STATUSES

    unauthorized_statuses.each do |status|
      @slot.update!(status: status)
      assert_not @slot.authorized_status?, "#{status} should not be authorized"
    end
  end

  test "to_param returns device_id" do
    assert_equal @slot.device_id, @slot.to_param
  end

  test "esp_url returns http URL for ip address" do
    @slot.update!(ip_address: "192.168.1.210")

    assert_equal "http://192.168.1.210", @slot.esp_url
  end

  test "register creates a coin slot and issues secret" do
    attributes = {
      name: "Registered Slot",
      device_id: "registered-slot",
      ip_address: "192.168.1.50",
      mac_address: "AA:BB:CC:DD:EE:50"
    }

    assert_difference("CoinSlot.count", 1) do
      coin_slot = CoinSlot.register(attributes)

      assert_equal "registered-slot", coin_slot.device_id
      assert_equal "Registered Slot", coin_slot.name
      assert coin_slot.secret.present?
    end
  end

  test "register updates existing coin slot by device_id" do
    attributes = {
      device_id: @slot.device_id,
      name: "Updated Slot",
      ip_address: "192.168.1.99",
      mac_address: "AA:BB:CC:DD:EE:99"
    }

    assert_no_difference("CoinSlot.count") do
      CoinSlot.register(attributes)
    end

    @slot.reload

    assert_equal "Updated Slot", @slot.name
    assert_equal "192.168.1.99", @slot.ip_address
    assert_equal "AA:BB:CC:DD:EE:99", @slot.mac_address
  end

  test "start_session! creates active session, activates slot, and queues enable command" do
    pc = pcs(:one)

    assert_difference("CoinSlotSession.count", 1) do
      assert_difference("EspCommandLog.count", 1) do
        assert_enqueued_with(job: CoinSlots::SessionTimerJob) do
          assert_enqueued_with(job: CoinSlots::EspCommandJob) do
            session = @slot.start_session!(pc)

            assert_equal @slot, session.coin_slot
            assert_equal pc, session.pc
            assert session.active?
          end
        end
      end
    end

    @slot.reload

    assert @slot.active?
    assert @slot.has_current_active_session?
    assert_equal "enable", @slot.esp_command_logs.order(:id).last.command
  end

  test "stop_session! stops active session and queues disable command" do
    session = @slot.start_session!(pcs(:one))
    clear_enqueued_jobs

    assert_difference("EspCommandLog.count", 1) do
      assert_enqueued_with(job: CoinSlots::EspCommandJob) do
        stopped_session = @slot.stop_session!

        assert_equal session, stopped_session
      end
    end

    session.reload
    @slot.reload

    assert session.stopped?
    assert session.ended?
    assert @slot.online?
    assert_not @slot.has_current_active_session?
    assert_equal "disable", @slot.esp_command_logs.order(:id).last.command
  end

  test "stop_session! returns nil when there is no active session" do
    @slot.coin_slot_sessions.update_all(status: CoinSlotSession.statuses[:stopped])

    assert_no_difference("EspCommandLog.count") do
      assert_nil @slot.reload.stop_session!
    end
  end

  test "receive_heartbeat! updates device attributes" do
    seen_at = Time.current.change(usec: 0)

    @slot.receive_heartbeat!(
      status: :offline,
      ip_address: "192.168.1.123",
      mac_address: "AA:BB:CC:DD:EE:12",
      last_seen_at: seen_at
    )

    @slot.reload

    assert @slot.offline?
    assert_equal "192.168.1.123", @slot.ip_address
    assert_equal "AA:BB:CC:DD:EE:12", @slot.mac_address
    assert_equal seen_at, @slot.last_seen_at
  end

  test "queue_esp_command! creates pending command and enqueues job" do
    freeze_time do
      command_log = nil

      assert_difference("EspCommandLog.count", 1) do
        assert_enqueued_with(job: CoinSlots::EspCommandJob) do
          command_log = @slot.queue_esp_command!(command: :enable)
        end
      end

      assert_equal @slot, command_log.coin_slot
      assert_equal "enable", command_log.command
      assert command_log.status_pending?
      assert_equal Time.current, command_log.sent_at
    end
  end

  test "restart! queues restart command and marks slot offline" do
    @slot.update!(status: :online)

    assert_difference("EspCommandLog.count", 1) do
      assert_enqueued_with(job: CoinSlots::EspCommandJob) do
        @slot.restart!
      end
    end

    @slot.reload

    assert @slot.offline?
    assert_equal "restart", @slot.esp_command_logs.order(:id).last.command
  end

  test "toggle_lock! locks authorized statuses" do
    CoinSlot::AUTHORIZED_STATUSES.each do |status|
      @slot.update!(status: status)

      @slot.toggle_lock!

      assert @slot.reload.locked?, "#{status} should lock"
    end
  end

  test "toggle_lock! unlocks locked slot to offline" do
    @slot.update!(status: :locked)

    @slot.toggle_lock!

    assert @slot.reload.offline?
  end
end
