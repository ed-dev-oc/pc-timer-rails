class Command < ApplicationRecord
  enum :status, [ :pending, :sent, :success, :failed ], prefix: :true

  delegated_type :commandable, types: %w[
    PcCommand
    CoinSlotCommand
  ], dependent: :destroy

  after_create_commit :schedule_job

  private
    def schedule_job
      ClientCommandJob.perform_later(self.id)
    end
end
