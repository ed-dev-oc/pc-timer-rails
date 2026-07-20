class CoinSlot < ApplicationRecord
  include ActionView::RecordIdentifier

  encrypts :secret
  enum :status, [ :active, :active_session, :offline, :locked ]
  AUTHORIZED_STATUSES = [ :active, :active_session, :offline ]

  has_many :coin_slot_sessions, dependent: :destroy
  has_one :active_coin_slot_session, -> { where(status: :active) }, class_name: "CoinSlotSession"
  has_many :coin_transactions, dependent: :destroy
  has_many :esp_command_logs, class_name: "EspCommandLog", dependent: :destroy

  validates :name, :mac_address, :ip_address, presence: true
  validates :name, :mac_address, :ip_address, uniqueness: true
  validates :device_id, uniqueness: true, allow_nil: true

  before_validation :issue_secret, on: :create

  def to_param
    device_id
  end

  def has_current_active_session?
    self.coin_slot_sessions.active.present?
  end

  def authorized_status?
    AUTHORIZED_STATUSES.include?(status.to_sym)
  end

  def broadcast_badge_status
    broadcast_replace_to(
      "badge_status",
      target: dom_id(self, :badge_status),
      partial: "shared/status_badge",
      locals: { object: self }
    )
  end

  def broadcast_session
    broadcast_replace_to(
      "coin_slot_session",
      target: dom_id(self, :session),
      partial: "winform/coin_slots/session",
      locals: { coin_slot: self }
    )
  end

  private

    def issue_secret
      self.secret = "sk_#{SecureRandom.hex(32)}"
    end
end
