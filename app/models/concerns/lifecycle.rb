module Lifecycle
  extend ActiveSupport::Concern

  def started?
    started_at.present?
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def ended?
    ended_at.present?
  end
end
