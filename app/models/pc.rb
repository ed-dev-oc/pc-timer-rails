class Pc < ApplicationRecord
  include ActionView::RecordIdentifier

  encrypts :secret
  enum :status, [ :offline, :online, :active_session, :disabled ]
  AUTHORIZED_STATUSES = [ :offline, :online, :active_session ]

  has_many :coin_slot_sessions
  has_one :active_coin_slot_session,
          -> { where(status: :active) },
          class_name: "CoinSlotSession"
  has_many :coin_transactions
  has_many :pc_sessions
  has_one :active_pc_session,
          -> { where(status: :active) },
          class_name: "PcSession"
  has_many :pc_command_logs, class_name: "PcCommandLog"

  validates :name, :device_id, presence: true, uniqueness: true
  validates :ip_address, :mac_address, presence: true

  after_update_commit :broadcast_status_change, if: :saved_change_to_status?
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
        status: :pending
      )
    end
  end

  def mark_online_and_lock_pc!
    transaction do
      online! if active_session?

      pc_command_logs.create!(
        command: :lock,
        status: :pending
      )
    end
  end

  def authenticated?(token)
    Digest::SHA256.hexdigest(token) == device_token_digest
  end

  def authorized_status?
    AUTHORIZED_STATUSES.include?(status.to_sym)
  end

  private

    def issue_secret
      self.secret = "sk_#{SecureRandom.hex(32)}"
    end

    def broadcast_status_change
      broadcast_replace_to(
        "pc_card",
        target: dom_id(self, :badge_status),
        partial: "winform/pcs/shared/badge_status",
        locals: { pc: self }
      )
    end
end
