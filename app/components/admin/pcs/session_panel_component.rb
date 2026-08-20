# frozen_string_literal: true

class Admin::Pcs::SessionPanelComponent < ViewComponent::Base
  def initialize(pc:)
    @pc = pc
  end

  private

  attr_reader :pc

  def pc_session
    @pc.reload.active_session
  end
end
