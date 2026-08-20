# frozen_string_literal: true

class Shared::SessionTimer::AlarmComponent < ViewComponent::Base
  def initialize(object:, source:, start_at:)
    @object = object
    @source = source
    @expires_at = object&.expires_at
    @start_at = start_at
  end

  def render?
    @object.present?
  end
end
