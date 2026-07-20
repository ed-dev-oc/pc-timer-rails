require "test_helper"

class CountDownComponentTest < ViewComponent::TestCase
  test "renders countdown component with remaining time" do
    coin_slot = coin_slots(:one)
    pc = pcs(:one)
    # Create a session that ends 5 minutes from now
    session = CoinSlotSession.create!(coin_slot: coin_slot, pc: pc)
    session.update!(ended_at: Time.current + 5.minutes)

    render_inline Shared::SessionTimer::CountDownComponent.new(
      object: session,
      session_object: session,
      session_duration_ms: Setting.duration("coin_slot_session_duration") * 1000,
      expires_at: session.ended_at,
      size: :small
    )
    # Expect the rendered HTML to contain a span with class text-success (default when time > 0)
    assert_selector "span.text-success"
    # The formatted timer should be present (e.g., "00:05:00")
    assert_match /\d{2}:\d{2}:\d{2}/, rendered_content
  end
end
