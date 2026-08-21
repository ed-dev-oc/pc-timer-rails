module CoinSlots
  class EspCommandJob < ApplicationJob
    queue_as :default

    retry_on Faraday::TimeoutError, wait: Setting.integer("esp_command_timeout_retry_wait").seconds, attempts: Setting.integer("esp_command_timeout_max_attempts")
    retry_on Faraday::ConnectionFailed, wait: Setting.integer("esp_connection_failed_retry_wait").seconds, attempts: Setting.integer("esp_command_max_attempts")

    # ✅ FINAL FAILURE HOOK
    after_discard do |job, error|
      command_log_id = job.arguments.first
      log = EspCommandLog.find(command_log_id)

      Rails.logger.error "❌ FINAL FAILURE: #{error.message}"

      log.update!(
        status: "failed",
        error_message: error.message,
        executed_at: Time.current
      )
    end

    def perform(command_log_id, coin_slot_session_id = nil)
      Rails.logger.info "🔥 Attempt ##{executions}"

      log = EspCommandLog.find(command_log_id)
      coin_slot = log.coin_slot
      coin_slot_session = coin_slot_session_id.present? ? CoinSlotSession.find_by(id: coin_slot_session_id) : nil
      agent = coin_slot.agent

      case log.command
      when "enable"
        agent.enable(coin_slot.active_session)
      when "disable"
        raise ArgumentError, "coin_slot_session_id is required for disable command" if coin_slot_session.nil?
        agent.disable(coin_slot_session)
      when "restart"
        agent.restart
      end

      log.update!(
        status: "success",
        executed_at: Time.current
      )
    end
  end
end
