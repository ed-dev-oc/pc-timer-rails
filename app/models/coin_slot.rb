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

  after_update_commit do
    self.reload

    broadcast_replace_to(
      "coin_slot_cards",
      target: dom_id(self),
      partial: "winform/coin_slots/coin_slot",
      locals: { coin_slot: self }
    )
  end

  def to_param
    device_id
  end

  def has_current_active_session?
    self.coin_slot_sessions.active.present?
  end





  def authorized_status?
    AUTHORIZED_STATUSES.include?(status.to_sym)
  end

  private

    def issue_secret
      self.secret = "sk_#{SecureRandom.hex(32)}"
    end
end
