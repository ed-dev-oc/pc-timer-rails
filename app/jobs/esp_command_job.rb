class EspCommandJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TimeoutError, wait: 3.seconds, attempts: 3
  retry_on Faraday::ConnectionFailed, wait: 5.seconds, attempts: 3

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
    client = EspClient.new(coin_slot)

    case log.command
    when "enable"
      client.enable(coin_slot.active_coin_slot_session)
    when "disable"
      coin_slot_session = CoinSlotSession.find(coin_slot_session_id)
      client.disable(coin_slot_session)
    when "restart"
      client.restart
    end

    log.update!(
      status: "success",
      executed_at: Time.current
    )
  end
end
