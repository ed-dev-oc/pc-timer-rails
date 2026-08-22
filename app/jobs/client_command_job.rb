class ClientCommandJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TimeoutError, wait: Setting.integer("pc_command_timeout_retry_wait").seconds, attempts: Setting.integer("pc_command_timeout_max_attempts")
  retry_on Faraday::ConnectionFailed, wait: Setting.integer("pc_connection_failed_retry_wait").seconds, attempts: Setting.integer("pc_command_max_attempts")

  # ✅ FINAL FAILURE HOOK
  after_discard do |job, error|
    command_id = job.arguments.first
    command = Command.find(command_id)

    Rails.logger.error "❌ FINAL FAILURE: #{error.message}"

    command.update!(
      status: "failed",
      error_message: error.message,
      executed_at: Time.current
    )
  end

  def perform(command_id)
    @command = Command.find(command_id)

    @command.commandable.execute!

    @command.update!(
      status: "success",
      executed_at: Time.current
    )
  end
end
