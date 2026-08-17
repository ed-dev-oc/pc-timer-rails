require "test_helper"

class CoinSlots::StatusHeartbeatJobTest < ActiveJob::TestCase
  setup do
    @coin_slot = coin_slots(:one)
    Setting.set("coin_slot_offline_threshold", 2, "integer")
    CoinSlot.update_all(status: CoinSlot.statuses[:offline], last_seen_at: Time.current)
    @coin_slot.reload
  end

  test "stale online coin slots are marked offline and broadcast" do
    @coin_slot.update!(status: :online, last_seen_at: 3.minutes.ago)
    changed_coin_slots = []

    CoinSlots::StatusChangedAction.stub(:call, ->(coin_slot) { changed_coin_slots << coin_slot }) do
      CoinSlots::StatusHeartbeatJob.perform_now
    end

    assert @coin_slot.reload.offline?
    assert_equal [ @coin_slot ], changed_coin_slots
  end

  test "recent online coin slots are left unchanged" do
    @coin_slot.update!(status: :online, last_seen_at: 1.minute.ago)

    CoinSlots::StatusChangedAction.stub(:call, ->(*) { flunk "status change should not be broadcast" }) do
      CoinSlots::StatusHeartbeatJob.perform_now
    end

    assert @coin_slot.reload.online?
  end

  test "stale active coin slots are left unchanged" do
    @coin_slot.update!(status: :active, last_seen_at: 3.minutes.ago)

    CoinSlots::StatusChangedAction.stub(:call, ->(*) { flunk "status change should not be broadcast" }) do
      CoinSlots::StatusHeartbeatJob.perform_now
    end

    assert @coin_slot.reload.active?
  end

  test "stale locked coin slots are left unchanged" do
    @coin_slot.update!(status: :locked, last_seen_at: 3.minutes.ago)

    CoinSlots::StatusChangedAction.stub(:call, ->(*) { flunk "status change should not be broadcast" }) do
      CoinSlots::StatusHeartbeatJob.perform_now
    end

    assert @coin_slot.reload.locked?
  end
end
