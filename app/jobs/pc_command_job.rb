class PcCommandJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TimeoutError, wait: Setting.integer('pc_command_timeout_retry_wait').seconds, attempts: Setting.integer('pc_command_timeout_max_attempts')
  retry_on Faraday::ConnectionFailed, wait: Setting.integer('pc_connection_failed_retry_wait').seconds, attempts: Setting.integer('pc_command_max_attempts')

  # ✅ FINAL FAILURE HOOK
  after_discard do |job, error|
    command_log_id = job.arguments.first
    log = PcCommandLog.find(command_log_id)

    Rails.logger.error "❌ FINAL FAILURE: #{error.message}"

    log.update!(
      status: "failed",
      error_message: error.message,
      executed_at: Time.current
    )
  end

  def perform(command_log_id)
    Rails.logger.info "🔥 Attempt ##{executions}"

    log = PcCommandLog.find(command_log_id)
    client = PcAgentClient.new(log.pc)

    case log.command
    when "restart"  then client.restart
    when "shutdown" then client.shutdown
    when "lock"     then client.lock
    when "unlock"   then client.unlock
    end

    log.update!(
      status: "success",
      executed_at: Time.current
    )
  end
end
