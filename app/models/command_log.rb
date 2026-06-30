class CommandLog < ApplicationRecord
  enum :status, [ :pending, :sent, :success, :failed ], prefix: :status
  belongs_to :pc, optional: true
  belongs_to :coin_slot, optional: true
end
