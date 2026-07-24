# frozen_string_literal: true

class Winform::Pcs::SessionPanelComponent < ViewComponent::Base
  def initialize(pc:)
    @pc = pc
  end

  private

  attr_reader :pc

  def pc_session
    @pc.active_pc_session
  end
end
