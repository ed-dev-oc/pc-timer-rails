require "test_helper"

class SessionControlsChangedTest < ActiveSupport::TestCase
  test "broadcasts replace for each component with correct target and html" do
    pc = pcs(:one)

    broadcast_calls = []
    # Stub the broadcast method to capture arguments
    Turbo::StreamsChannel.stub(:broadcast_replace_later_to, ->(*args) { broadcast_calls << args }) do
      # Stub rendering of components to a simple placeholder string
      ApplicationController.stub(:render, ->(*_render_args) { "<div>component</div>" }) do
        Pcs::SessionControlsChanged.call(pc)
      end
    end

    # Expect two broadcasts, one for each component defined in the service
    assert_equal 2, broadcast_calls.size, "Expected two broadcast calls"

    expected_targets = {
      "coin_slot_button" => ActionView::RecordIdentifier.dom_id(pc, :coin_slot_button),
      "pc_session_button" => ActionView::RecordIdentifier.dom_id(pc, :pc_session_button)
    }

    broadcast_calls.each do |channel, options|
      # Channel name should match the component key
      assert_includes expected_targets.keys, channel
      # Verify the target DOM id matches expectation
      assert_equal expected_targets[channel], options[:target]
      # Verify html is the placeholder rendered string
      assert_equal "<div>component</div>", options[:html]
    end
  end
end
