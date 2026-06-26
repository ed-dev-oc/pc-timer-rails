class CommandLog < ApplicationRecord
  enum :status, [ :pending, :sent, :success, :failed ], prefix: :status
end
