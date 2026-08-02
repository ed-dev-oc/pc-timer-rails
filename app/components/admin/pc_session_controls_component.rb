# frozen_string_literal: true

class Admin::PcSessionControlsComponent < ViewComponent::Base
  def initialize(pc:)
    @pc = pc
  end

  private

  attr_reader :pc

  def pc_session
    @pc.active_session
  end
end
