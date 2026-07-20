class CoinSlotSession < ApplicationRecord
  generate_public_uid generator: PublicUid::Generators::NumberRandom.new
  include ActionView::RecordIdentifier
  include PublicUid::ModelConcern

  enum :status, [ :active, :inactive ]

  belongs_to :coin_slot
  belongs_to :pc

  validates :started_at, :ended_at, presence: true
  validates :status, inclusion: { in: [ "active" ] }, on: :create
  validate :coin_slot_has_only_one_session!, on: :create

  before_validation :set_started_and_ended_at

  def mark_inactive_and_disable_esp!
    transaction do
      inactive!
      coin_slot.esp_command_logs.create!(
        command: :disable,
        status: :pending,
        sent_at: Time.current,
        coin_slot_session: self
      )
    end
  end

  private

    def set_started_and_ended_at
      self.started_at = Time.current
      self.ended_at = Time.current + Setting.duration("coin_slot_session_duration").seconds
    end

    def coin_slot_has_only_one_session!
      coin_slot = self.coin_slot

      if coin_slot&.coin_slot_sessions.active.present?
        errors.add(:base, "Coin slot currently used!")
      end
    end
end
