require "test_helper"

class PcSessionsBroadcastServiceTest < ActiveSupport::TestCase
  test "broadcasts all components and invokes dependent services" do
    pc = pcs(:one)

    # Capture Turbo broadcast calls
    broadcast_calls = []
    Turbo::StreamsChannel.stub(:broadcast_replace_later_to, ->(*args) { broadcast_calls << args }) do
      # Stub component rendering to a simple placeholder string
      ApplicationController.stub(:render, ->(*_render_args) { "<div>component</div>" }) do
        # Flags to verify that dependent service calls were made
        pcs_status_called = false
        pcs_session_called = false
        coin_slot_changed_called = false

        Pcs::StatusChangedAction.stub(:call, ->(_pc) { pcs_status_called = true }) do
          Pcs::SessionControlsChanged.stub(:call, ->(_pc) { pcs_session_called = true }) do
            CoinSlotSessions::ChangedAction.stub(:call, ->(_session) { coin_slot_changed_called = true }) do
              PcSessions::BroadcastService.call(pc)
            end
          end
        end

        # Verify that the dependent services were invoked
        assert pcs_status_called, "Pcs::StatusChangedAction should be called"
        assert pcs_session_called, "Pcs::SessionControlsChanged should be called"
        assert coin_slot_changed_called, "CoinSlotSessions::ChangedAction should be called when a coin slot session exists"
      end
    end

    # Expect four Turbo broadcasts: session panel, admin panel, minimize component, admin controls
    assert_equal 4, broadcast_calls.size, "Expected four Turbo broadcast calls"

    broadcast_calls.each do |channel, opts|
      case channel
      when "pc_session"
        # Two possible targets for the "pc_session" channel: the main panel or the minimize component
        valid_targets = [
          ActionView::RecordIdentifier.dom_id(pc, :pc_session),
          ActionView::RecordIdentifier.dom_id(pc, :pc_session_minimize)
        ]
        assert_includes valid_targets, opts[:target], "Unexpected target for pc_session broadcast"
        assert_equal "<div>component</div>", opts[:html]
      when "admin_pc_session"
        # Admin session panel component uses the same target as the regular session panel
        expected_target = ActionView::RecordIdentifier.dom_id(pc, :pc_session)
        assert_equal expected_target, opts[:target]
        assert_equal "<div>component</div>", opts[:html]
      when "pc_session_controls"
        expected_target = ActionView::RecordIdentifier.dom_id(pc, :pc_session_controls)
        assert_equal expected_target, opts[:target]
        assert_equal "<div>component</div>", opts[:html]
      else
        flunk "Unexpected broadcast channel #{channel}"
      end
    end
  end
end
