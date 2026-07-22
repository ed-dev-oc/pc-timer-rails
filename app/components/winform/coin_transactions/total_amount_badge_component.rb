module Winform
  module CoinTransactions
    class TotalAmountBadgeComponent < ViewComponent::Base
      def initialize(pc:)
        @pc = pc
      end
    end
  end
end
