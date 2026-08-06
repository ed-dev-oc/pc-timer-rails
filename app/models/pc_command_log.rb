class PcCommandLog < CommandLog
  enum :command, [ :lock, :unlock, :restart, :shutdown ], prefix: :command

  belongs_to :pc

  validates :pc, presence: true
  after_create_commit :enqueue_job

  private

    def enqueue_job
      Pcs::CommandJob.set(wait_until: 2.seconds.from_now).perform_later(self.id)
    end
end
