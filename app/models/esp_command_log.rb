class EspCommandLog < CommandLog
  enum :command, [ :enable, :disable ], prefix: :command

  belongs_to :coin_slot

  validates :coin_slot, presence: true
  after_create_commit :enqueue_job

  private

    def enqueue_job
      EspCommandJob.set(wait_until: 2.seconds.from_now).perform_later(self.id)
    end
end
