class CoinSlotSession < ApplicationRecord
  generate_public_uid generator: PublicUid::Generators::NumberRandom.new
  include ActionView::RecordIdentifier
  include PublicUid::ModelConcern

  EXPIRATION_MINUTE = 1
  enum :status, [ :active, :inactive ]

  belongs_to :coin_slot
  belongs_to :pc

  validates :started_at, :ended_at, presence: true
  validates :status, inclusion: { in: [ "active" ] }, on: :create
  validate :coin_slot_has_only_one_session!, on: :create

  before_validation :set_started_and_ended_at
  after_create :set_coin_slot_status_to_active_session
  after_update :set_coin_slot_status_to_active

  after_update_commit do
    broadcast_replace_to(
      "coin_slot_session_button",
      target: dom_id(self.pc, :insert_coin_card),
      partial: "winform/pcs/button",
      locals: { pc: self.pc }
    )
  end

  def mark_inactive_and_disable_esp!
    transaction do
      inactive!
      coin_slot.esp_command_logs.create!(
        command: :disable,
        status: :pending
      )
    end
  end

  private

    def set_started_and_ended_at
      self.started_at = Time.current
      self.ended_at = Time.current + EXPIRATION_MINUTE.minute
    end

    def coin_slot_has_only_one_session!
      coin_slot = self.coin_slot

      if coin_slot&.coin_slot_sessions.active.present?
        errors.add(:base, "Coin slot currently used!")
      end
    end

    def set_coin_slot_status_to_active_session
      self.coin_slot&.active_session!
    end

    def set_coin_slot_status_to_active
      coin_slot.active! if self.inactive?
    end
end
