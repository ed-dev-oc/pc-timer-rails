# frozen_string_literal: true

class Shared::Flash::ContainerComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(flash: nil)
    @flash = flash || {}
  end
end
