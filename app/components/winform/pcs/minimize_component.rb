module Winform
  module Pcs
    class MinimizeComponent < ViewComponent::Base
      # Expose the objects needed in the template
      def initialize(pc:)
        @pc = pc
      end

      private

      attr_reader :pc

      def pc_session
        @pc.active_pc_session
      end
    end
  end
end
