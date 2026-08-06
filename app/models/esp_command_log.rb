class EspCommandLog < CommandLog
  attr_accessor :coin_slot_session

  enum :command, [ :enable, :disable, :restart ], prefix: :command

  belongs_to :coin_slot

  validates :coin_slot, presence: true
  after_create_commit :enqueue_job

  private

    def enqueue_job
      CoinSlots::EspCommandJob.set(wait_until: 2.seconds.from_now).perform_later(self.id, coin_slot_session&.id)
    end
end
