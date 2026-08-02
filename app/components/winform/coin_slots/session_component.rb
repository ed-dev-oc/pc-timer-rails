module Winform
  module CoinSlots
    class SessionComponent < ViewComponent::Base
      # Initialize with the parent CoinSlot model. The component decides whether a session exists.
      # +empty_message+ can be overridden by callers (e.g., admin UI) to customize the no‑session text.
      def initialize(coin_slot:, empty_message: nil)
        @coin_slot = coin_slot
        @empty_message = empty_message
      end

      private

      attr_reader :coin_slot, :empty_message

      # Returns true when the coin slot has an active session.
      def active_session?
        coin_slot.has_current_active_session?
      end

      # Convenience accessor for the active session object.
      def coin_slot_session
        coin_slot.active_session
      end

      # Renders the default "No Active Session" badge. Callers may supply +empty_message+.
      def no_session_markup
        content_tag(:div, class: "text-center") do
          content_tag(
            :span,
            (empty_message || "No Active Session"),
            class: "badge text-bg-secondary py-2"
          )
        end
      end
    end
  end
end
