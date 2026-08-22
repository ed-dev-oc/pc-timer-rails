class CoinSlot < ApplicationRecord
  include ActionView::RecordIdentifier

  encrypts :secret
  # Updated status enum: replace :active with :online
  # Updated status enum: replace :active_session with :active
  enum :status, [ :online, :active, :offline, :locked ]
  AUTHORIZED_STATUSES = [ :online, :active, :offline ]

  attribute :last_seen_at, :datetime, default: -> { Time.current }

  has_many :coin_slot_sessions, dependent: :destroy
  has_one :active_session, -> { active }, class_name: "CoinSlotSession"
  has_many :coin_transactions, dependent: :destroy
  has_many :esp_command_logs, class_name: "EspCommandLog", dependent: :destroy
  has_many :coin_slot_commands, dependent: :destroy
  has_many :commands,
          through: :coin_slot_commands,
          source: :command

  validates :name, :mac_address, :ip_address, presence: true
  validates :name, :mac_address, :ip_address, uniqueness: true
  validates :device_id, uniqueness: true, allow_nil: true

  before_validation :issue_secret, on: :create

  def to_param
    device_id
  end

  def esp_url
    "http://#{ip_address}"
  end

  def agent
    Agent.new(self)
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
      coin_slot_session = CoinSlotSession.start!(self, pc)
      active!
      queue_command!(action: :enable, coin_slot_session: coin_slot_session)

      self.reload
      coin_slot_session
    end
  end

  def stop_session!
    session = active_session
    session&.stop!

    self.reload
    session
  end

  def receive_heartbeat!(attributes)
    update!(attributes)
  end

  def queue_command!(action:, coin_slot_session: nil)
    Command.create!(
      commandable: self.coin_slot_commands.new(action: action, coin_slot_session: coin_slot_session),
      sent_at: Time.current
    )
  end

  def restart!
    transaction do
      queue_command!(command: :restart)
      offline!
    end
  end

  def toggle_lock!
    new_status =
      if AUTHORIZED_STATUSES.include?(status.to_sym)
        :locked
      else
        :offline
      end

    update!(status: new_status)
  end

  private

    def issue_secret
      self.secret = "sk_#{SecureRandom.hex(32)}"
    end
end
