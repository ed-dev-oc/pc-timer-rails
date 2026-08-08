class Pc < ApplicationRecord
  class NoInsertedCoinsError < StandardError; end

  include ActionView::RecordIdentifier

  encrypts :secret
  # Rename enum value :active_session to :active (status representing an active PC session)
  enum :status, [ :offline, :online, :active, :disabled_kiosk, :uninstalled ]
  AUTHORIZED_STATUSES = [ :offline, :online, :active, :disabled_kiosk ]

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

  has_one :active_session,
          -> { active },
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

  def authorized_status?
    AUTHORIZED_STATUSES.include?(status.to_sym)
  end

  def start_session!
    unused_credits = coin_transactions.unused
    raise NoInsertedCoinsError, "No inserted coin found." if unused_credits.empty?

    transaction do
      PcSession.start!(self, unused_credits)
      mark_active_session_and_unlock_pc!
      active_coin_slot&.stop_session!
    end

    self.reload
  end

  def start_manual_session!(attributes)
    transaction do
      PcSession.start_manual!(attributes)
      mark_active_session_and_unlock_pc!
    end
  end

  def extend_session!(session)
    unused_credits = coin_transactions.unused
    raise NoInsertedCoinsError, "No inserted coin found." if unused_credits.empty?

    transaction do
      session.extend!(unused_credits)
      mark_active_session_and_unlock_pc!
      active_coin_slot&.stop_session!
    end
  end

  def stop_session!(session)
    transaction do
      session.stop!
      mark_online_and_lock_pc!
      schedule_shutdown
    end

    self.reload
  end

  def self.register!(attributes)
    pc = find_or_initialize_by(device_id: attributes[:device_id])
    pc.assign_attributes(attributes)
    pc.save!

    pc
  end

  def signin!
    pc_session = active_session
    pc_status = self.status

    unless disabled_kiosk?
      pc_status = pc_session.present? ? :active : :online
    end

    update!(status: pc_status)
  end

  def signout!
    update!(status: :offline, last_seen_at: Time.current)
  end

  def shutdown!
    transaction do
      queue_pc_command!(:shutdown)
      offline!
    end
  end

  def restart!
    transaction do
      queue_pc_command!(:restart)
      offline!
    end
  end

  def receive_heartbeat!(attributes)
    update!(attributes)
  end

  def active_session_json
    pc_session = active_session

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

    def queue_pc_command!(command)
      pc_command_logs.create!(
        command: command,
        status: :pending,
        sent_at: Time.current
      )
    end

    def mark_active_session_and_unlock_pc!
      transaction do
        # Update status to :active (previously :active_session)
        active!

        queue_pc_command!(:unlock)
      end
    end

    def mark_online_and_lock_pc!
      transaction do
        online! if active?

        queue_pc_command!(:lock)
      end
    end

    def schedule_shutdown
      # Use configurable wait time from settings (default 300 seconds)
      wait_seconds = Setting.duration("pc_shutdown_wait_time")
      Pcs::ShutdownScheduleJob
        .set(wait_until: wait_seconds.seconds.from_now)
        .perform_later(id)
    end
end
