class CoinTransaction < ApplicationRecord
  include ActionView::RecordIdentifier


  enum :status, [ :unused, :used ]

  belongs_to :coin_slot
  belongs_to :pc

  validates :transaction_uid, :peso_amount, :minutes_granted, presence: true
  validates :transaction_uid, uniqueness: true
  validates :peso_amount, numericality: { only_integer: true }
  validates :minutes_granted, numericality: { only_integer: true, greater_than: 0 }

  before_validation :set_minutes_granted

  after_commit do
    pc = self.pc.reload

    broadcast_replace_to(
      "coin_slot_session_button",
      target: dom_id(pc, :inserted_amount),
      partial: "winform/coin_transactions/total_amount_badge",
      locals: { pc: pc }
    )

    broadcast_replace_to(
      "coin_slot_session_button",
      target: dom_id(pc, :insert_coin_card),
      partial: "winform/pcs/button",
      locals: { pc: pc }
    )
  end

  private

    def set_minutes_granted
      return if peso_amount.blank? || peso_amount.zero?

      self.minutes_granted = Setting.integer('minutes_per_credit') * peso_amount
    end
end
