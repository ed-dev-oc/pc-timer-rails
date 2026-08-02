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

  scope :unused, -> { where(status: :unused) }

  after_update_commit do
    CoinTransactions::BroadcastService.call(self.pc)
  end

  def mark_used!
    self.used!
  end

  def self.insert_coin!(attributes)
    create!(attributes)
  end

  private

    def set_minutes_granted
      return if peso_amount.blank? || peso_amount.zero?

      self.minutes_granted = Setting.integer("minutes_per_credit") * peso_amount
    end
end
