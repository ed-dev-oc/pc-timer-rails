class PcSession < ApplicationRecord
  generate_public_uid
  include ActionView::RecordIdentifier

  enum :status, [ :active, :ended ]

  belongs_to :pc

  validates :total_minutes_purchased, :started_at, :expires_at, :total_amount, presence: true
  validates :total_minutes_purchased, numericality: { only_integer: true, greater_than: 0 }
  validates :total_amount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :public_uid, uniqueness: true

  validate :has_one_pc_session_active!, on: :create
  validate :peso_amount_meets_minimum_credit, if: :coin_funded_session?

  def to_param
    public_uid
  end

  def total_remaining_seconds
    current_time = Time.current

    if self.ended? || expires_at < current_time
     return 0
    end

    (expires_at - current_time).ceil
  end

  def total_duration_formatted
    minutes = total_minutes_purchased.to_i
    total_seconds = minutes * 60
    Time.at(total_seconds).utc.strftime("%H:%M:%S")
  end

  def total_purchased_duration_ms
    total_minutes_purchased * 60 * 1000
  end

  private

    def has_one_pc_session_active!
      if pc.active_pc_session.present?
        errors.add(:base, "This PC already have active session!")
      end
    end

    def coin_funded_session?
      pc.coin_transactions.unused.exists?
    end

    def peso_amount_meets_minimum_credit
      minimum_credit = Setting.integer("minimum_credit")
      inserted_amount = pc.coin_transactions.unused.sum(:peso_amount)

      if inserted_amount < minimum_credit
        # errors.add(:total_amount, "must be greater than or equal to #{minimum_credit}")
        errors.add(:base, "Please insert ₱#{minimum_credit} or more to play!")
      end
    end
end
