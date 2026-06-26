class PcCommandJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TimeoutError, wait: 3.seconds, attempts: 3
  retry_on Faraday::ConnectionFailed, wait: 5.seconds, attempts: 3

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
