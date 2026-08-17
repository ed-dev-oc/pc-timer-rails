class CoinSlotSession < ApplicationRecord
  generate_public_uid generator: PublicUid::Generators::NumberRandom.new
  include ActionView::RecordIdentifier
  include PublicUid::ModelConcern
  include Lifecycle

  enum :status, [ :active, :stopped ]

  belongs_to :coin_slot
  belongs_to :pc

  validates :started_at, :expires_at, presence: true
  validates :status, inclusion: { in: [ "active" ] }, on: :create
  validate :coin_slot_has_only_one_session!, on: :create

  before_validation :set_started_and_expires_at, on: :create

  scope :active, -> { where(status: :active) }

  def self.start!(coin_slot, pc)
    transaction do
      session = create!(pc: pc, coin_slot: coin_slot)
      session.schedule_expiration
      session
    end
  end

  def stop!
    transaction do
      stopped!
      update!(ended_at: Time.current)
      coin_slot.online!
      coin_slot.queue_esp_command!(command: :disable, coin_slot_session: self)
    end
  end

  def schedule_expiration
    CoinSlots::SessionTimerJob.set(wait_until: expires_at).perform_later(id)
  end

  private

    def set_started_and_expires_at
      self.started_at = Time.current
      self.expires_at = Time.current + Setting.duration("coin_slot_session_duration").seconds
    end

    def coin_slot_has_only_one_session!
      coin_slot = self.coin_slot

      if coin_slot&.active_session.present?
        errors.add(:base, "Coin slot currently used!")
      end
    end
end
