require "test_helper"

class Pcs::StatusHeartbeatJobTest < ActiveJob::TestCase
  setup do
    @pc = pcs(:one)
    Setting.set("pc_offline_threshold", 2, "integer")
    Pc.update_all(status: Pc.statuses[:offline], last_seen_at: Time.current)
    @pc.reload
  end

  test "stale online PCs are marked offline and broadcast" do
    @pc.update!(status: :online, last_seen_at: 3.minutes.ago)
    changed_pcs = []

    Pcs::StatusChangedAction.stub(:call, ->(pc) { changed_pcs << pc }) do
      Pcs::StatusHeartbeatJob.perform_now
    end

    assert @pc.reload.offline?
    assert_equal [ @pc ], changed_pcs
  end

  test "recent online PCs are left unchanged" do
    @pc.update!(status: :online, last_seen_at: 1.minute.ago)

    Pcs::StatusChangedAction.stub(:call, ->(*) { flunk "status change should not be broadcast" }) do
      Pcs::StatusHeartbeatJob.perform_now
    end

    assert @pc.reload.online?
  end

  test "stale active PCs are left unchanged" do
    @pc.update!(status: :active, last_seen_at: 3.minutes.ago)

    Pcs::StatusChangedAction.stub(:call, ->(*) { flunk "status change should not be broadcast" }) do
      Pcs::StatusHeartbeatJob.perform_now
    end

    assert @pc.reload.active?
  end

  test "stale immutable PCs are left unchanged" do
    @pc.update_columns(status: Pc.statuses[:disabled_kiosk], last_seen_at: 3.minutes.ago)

    Pcs::StatusChangedAction.stub(:call, ->(*) { flunk "status change should not be broadcast" }) do
      Pcs::StatusHeartbeatJob.perform_now
    end

    assert @pc.reload.disabled_kiosk?
  end
end
