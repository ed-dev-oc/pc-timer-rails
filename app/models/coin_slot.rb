class CoinSlot < ApplicationRecord
  include ActionView::RecordIdentifier

  encrypts :secret
  enum :status, [ :active, :active_session, :offline, :locked ]
  AUTHORIZED_STATUSES = [ :active, :active_session, :offline ]

  attribute :last_seen_at, :datetime, default: -> { Time.current }

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

  def self.register(attributes)
    coin_slot = find_or_initialize_by(device_id: attributes[:device_id])

    coin_slot.assign_attributes(attributes.slice(:name, :ip_address, :mac_address))
    coin_slot.save!

    coin_slot
  end

  def start_session!(pc)
    transaction do
      coin_slot_session = coin_slot_sessions.create!(pc: pc)
      active_session!

      coin_slot_session
    end
  end

  def reaceive_heartbeat!(attributes)
    # Updated method name to correctly reflect its purpose.
    # It updates the coin slot with the incoming heartbeat attributes
    # and broadcasts the updated badge status.
    update!(attributes)
    broadcast_badge!
  end

  def queue_esp_command!(command:, coin_slot_session: nil)
    # Use the current instance (`self`) to create the ESP command log.
    self.esp_command_logs.create!(
      command: command,
      status: :pending,
      sent_at: Time.current,
      coin_slot_session: coin_slot_session
    )
  end

  def restart!
    transaction do
      queue_esp_command!(command: :restart)
      offline!
    end

    broadcast_badge!
  end

  def toggle_lock!
    new_status =
      if AUTHORIZED_STATUSES.include?(status.to_sym)
        :locked
      else
        :offline
      end

    update!(status: new_status)

    broadcast_badge!
  end

  def broadcast_badge!
    CoinSlots::Broadcasts::BadgeStatus.call(self)
  end

  def broadcast_session!
    CoinSlots::Broadcasts::Session.call(self)
  end

  private

    def issue_secret
      self.secret = "sk_#{SecureRandom.hex(32)}"
    end
end
