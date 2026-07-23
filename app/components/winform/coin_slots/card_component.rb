module Winform
  module CoinSlots
    class CardComponent < ViewComponent::Base
      # Initialize with a CoinSlot model instance
      def initialize(coin_slot:)
        @coin_slot = coin_slot
      end

      private

      attr_reader :coin_slot
    end
  end
end
