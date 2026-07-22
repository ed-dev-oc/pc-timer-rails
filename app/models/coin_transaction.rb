class CoinTransaction < ApplicationRecord
  include ActionView::RecordIdentifier


  enum :status, [ :unused, :used ]

  belongs_to :coin_slot
  belongs_to :pc

  validates :transaction_uid, :peso_amount, :minutes_granted, presence: true
  validates :transaction_uid, uniqueness: true
  validates :peso_amount, numericality: { only_integer: true, greater_than: 0 }
  validates :minutes_granted, numericality: { only_integer: true, greater_than: 0 }

  before_validation :set_minutes_granted

  # Broadcasting is now handled explicitly after a successful save in the
  # controller (or other service) via CoinTransaction::BroadcastService.

  # Ensure broadcasts also occur when a transaction is updated (e.g., status change).
  after_update_commit do
    CoinTransaction::BroadcastService.call(self.pc)
  end

  private

    def set_minutes_granted
      return if peso_amount.blank? || peso_amount.zero?

      self.minutes_granted = Setting.integer("minutes_per_credit") * peso_amount
    end
end
