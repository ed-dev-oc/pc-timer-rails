class Pc < ApplicationRecord
  include ActionView::RecordIdentifier

  encrypts :secret
  enum :status, [ :offline, :online, :active_session, :disabled_kiosk, :uninstalled ]
  AUTHORIZED_STATUSES = [ :offline, :online, :active_session, :disabled_kiosk ]

  has_many :coin_slot_sessions, dependent: :destroy
  has_many :coin_transactions, dependent: :destroy
  has_many :pc_sessions, dependent: :destroy
  has_many :pc_command_logs, class_name: "PcCommandLog", dependent: :destroy

  has_one :active_coin_slot_session,
          -> { where(status: :active) },
          class_name: "CoinSlotSession"
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

      pc_command_logs.create!(
        command: :unlock,
        status: :pending,
        sent_at: Time.current
      )
    end
  end

  def mark_online_and_lock_pc!
    transaction do
      online! if active_session?

      pc_command_logs.create!(
        command: :lock,
        status: :pending,
        sent_at: Time.current
      )
    end
  end

  def authorized_status?
    AUTHORIZED_STATUSES.include?(status.to_sym)
  end

  # The enum `status` already provides the predicate `active_session?`.
  # The legacy `active?` method has been removed as it was only used in tests.

  private

    def issue_secret
      self.secret = "sk_#{SecureRandom.hex(32)}"
    end
end
