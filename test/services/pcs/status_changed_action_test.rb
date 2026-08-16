require "test_helper"

class PcsStatusChangedActionTest < ActiveSupport::TestCase
  test "broadcasts badge status with correct DOM id and partial" do
    pc = pcs(:one)

    broadcast_args = nil
    Turbo::StreamsChannel.stub(:broadcast_replace_later_to, ->(*args) { broadcast_args = args }) do
      Pcs::StatusChangedAction.call(pc)
    end

    assert_not_nil broadcast_args, "Turbo broadcast should be invoked"
    # Verify channel name
    assert_equal "badge_status", broadcast_args[0]
    opts = broadcast_args[1]
    expected_target = ActionView::RecordIdentifier.dom_id(pc, :badge_status)
    assert_equal expected_target, opts[:target]
    assert_equal "shared/status_badge", opts[:partial]
    # The broadcast includes both the generic object key and a model‑specific key added by the instance method
    expected_locals = { object: pc, pc: pc }
    assert_equal expected_locals, opts[:locals]
  end
end
