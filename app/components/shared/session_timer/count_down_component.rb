# frozen_string_literal: true

class Shared::SessionTimer::CountDownComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(object:, session_object:, session_duration_ms:, expires_at:, size: :small)
    @object = object
    @session_object = session_object
    @size = size
    @expires_at = expires_at
    @session_duration_ms = session_duration_ms
  end

  def count_down_size
    {
      small: "fs-5",
      medium: "fs-3",
      large: "fs-1"
    }.fetch(@size, "fs-5")
  end

  def render?
    @session_object.present?
  end
end
