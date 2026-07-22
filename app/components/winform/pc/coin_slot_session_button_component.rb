# frozen_string_literal: true

class Winform::Pc::CoinSlotSessionButtonComponent < ViewComponent::Base
  # Accept a Pc record so the template can use its methods.
  def initialize(pc:)
    @pc = pc
  end

  attr_reader :pc
end
