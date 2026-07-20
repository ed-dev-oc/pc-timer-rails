# frozen_string_literal: true

class Shared::SessionTimer::ProgressBarComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(object:, session_object:, session_duration_ms:, expires_at:)
    @object = object
    @session_object = session_object
    @expires_at = expires_at
    @session_duration_ms = session_duration_ms
  end

  def render?
    @session_object.present?
  end
end
