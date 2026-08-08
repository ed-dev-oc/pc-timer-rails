# frozen_string_literal: true

class Ui::StatusBadgeComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(object:)
    @object = object
    @status = object.status.to_s
  end

  private
    attr_reader :status
    attr_reader :object

    def variant
      {
        "active"     => "text-bg-warning",
        "inactive"   => "text-bg-secondary",
        "offline"    => "text-bg-secondary",
        "online"   => "text-bg-primary",
        "disabled_kiosk" => "text-bg-danger",
        "uninstalled"     => "text-bg-dark",
        "used" => "text-bg-success",
        "unused" => "text-bg-secondary",
        "stopped" => "text-bg-secondary",
        "locked" => "text-bg-dark",
        "pending" => "text-bg-secondary",
        "sent" => "text-bg-primary",
        "success" => "text-bg-success",
        "failed" => "text-bg-danger"
      }.fetch(status, "text-bg-secondary")
    end

    def icon
      {
        "active"     => "bi-play-circle-fill",
        "inactive"   => "bi-stop-circle-fill",
        "offline"    => "bi-wifi-off",
        "online"   => "bi-wifi",
        "disabled_kiosk" => "bi-lock",
        "uninstalled"     => "bi-trash3",
        "used" => "bi-check-circle-fill",
        "unused" => "bi-circle",
        "stopped" => "bi-stop-circle-fill",
        "locked" => "bi-lock-fill",
        "pending" => "bi-hourglass-split",
        "sent" => "bi-send-check",
        "success" => "bi-check-circle-fill",
        "failed" => "bi-x-circle-fill"
      }.fetch(status, "bi-question-circle")
    end
end
