class Pc < ApplicationRecord
  class NoInsertedCoinsError < StandardError; end

  include ActionView::RecordIdentifier

  encrypts :secret
  enum :status, [ :offline, :online, :active_session, :disabled_kiosk, :uninstalled ]
  AUTHORIZED_STATUSES = [ :offline, :online, :active_session, :disabled_kiosk ]

  has_many :coin_slot_sessions, dependent: :destroy
  has_many :coin_transactions, dependent: :destroy
  has_many :pc_sessions, dependent: :destroy
  has_many :pc_command_logs, class_name: "PcCommandLog", dependent: :destroy

  has_one :active_coin_slot_session,
          -> { active },
          class_name: "CoinSlotSession"
  has_one :active_coin_slot,
          through: :active_coin_slot_session,
          source: :coin_slot

  has_one :active_pc_session,
          -> { where(status: :active) },
          class_name: "PcSession"

  validates :name, :device_id, presence: true, uniqueness: true
  validates :ip_address, :mac_address, presence: true

  before_validation :issue_secret, on: :create

  def to_param
    device_id
  end

  def has_active_coin_slot_session?
    coin_slot_sessions.active.present?
  end

  def has_unused_coin_transaction?
    coin_transactions.unused.present?
  end

  def mark_active_session_and_unlock_pc!
    transaction do
      active_session!

      queue_pc_command!(:unlock)
    end
  end

  def mark_online_and_lock_pc!
    transaction do
      online! if active_session?

      queue_pc_command!(:lock)
    end
  end

  def authorized_status?
    AUTHORIZED_STATUSES.include?(status.to_sym)
  end

  def start_session!
    unused_credits = coin_transactions.unused
    raise NoInsertedCoinsError, "No inserted coin found." if unused_credits.empty?

    transaction do
      PcSession.start!(self, unused_credits)
      mark_active_session_and_unlock_pc!
      active_coin_slot_session&.stop_session!
    end

    self.reload
    broadcast_badge!
    broadcast_session!
  end

  def start_manual_session!(attributes)
    transaction do
      PcSession.start_manual!(attributes)
      mark_active_session_and_unlock_pc!
    end

    self.reload
    broadcast_badge!
    broadcast_session!
  end

  def extend_session!(session)
    unused_credits = coin_transactions.unused
    raise NoInsertedCoinsError, "No inserted coin found." if unused_credits.empty?

    transaction do
      session.extend!(unused_credits)
      mark_active_session_and_unlock_pc!
      active_coin_slot_session&.stop_session!
    end

    self.reload
    broadcast_badge!
    broadcast_session!
  end

  def stop_session!(session)
    transaction do
      session.stop!
      mark_online_and_lock_pc!
    end

    self.reload
    broadcast_badge!
    broadcast_session!
  end

  def self.register!(attributes)
    pc = find_or_initialize_by(device_id: attributes[:device_id])
    pc.assign_attributes(attributes.slice(:name, :ip_address, :mac_address))
    pc.save!
    broadcast_badge!

    pc
  end

  def signin!
    pc_session = active_pc_session
    pc_status = self.status

    unless disabled_kiosk?
      pc_status = pc_session.present? ? :active_session : :online
    end

    update!(status: pc_status)
  end

  def signout!
    update!(status: :offline, last_seen_at: Time.current)
    broadcast_badge!
  end

  def receive_heartbeat!(attributes)
    update!(attributes)
    broadcast_badge!
  end

  def queue_pc_command!(command)
    pc_command_logs.create!(
      command: command,
      status: :pending,
      sent_at: Time.current
    )
  end

  def broadcast_badge!
    Pcs::Broadcasts::BadgeStatus.call(self)
  end

  def broadcast_session!
    PcSessions::BroadcastService.call(self)
  end

  def active_session_json
    pc_session = active_pc_session

    pc_session.present? ? {
      id: pc_session&.public_uid,
      status: pc_session&.status,
      expires_at_utc: pc_session&.expires_at&.utc
    } : nil
  end

  private

    def issue_secret
      self.secret = "sk_#{SecureRandom.hex(32)}"
    end
end
