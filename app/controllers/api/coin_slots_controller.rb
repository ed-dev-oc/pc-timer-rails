class Api::CoinSlotsController < Api::BaseController
  before_action :authenticate_device!, :set_coin_slot!, except: [ :register ]

  def register
    @coin_slot = CoinSlot.register(coin_slot_params)

    response_json = {
      status: "success",
      coin_slot_id: @coin_slot.id,
      device_id: @coin_slot.device_id,
      secret: @coin_slot.secret
    }

    render json: response_json, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render_validation_failed(e.record)
  end

  def heartbeat
    @coin_slot.receive_heartbeat!(coin_slot_update_params)

    CoinSlots::Broadcasts::BadgeStatus.call(@coin_slot)

    render json: {
      status: "success",
      message: "Heartbeat received",
      coin_slot_status: @coin_slot.status
    }, status: :ok
  rescue ActiveRecord::RecordInvalid
    render_validation_failed(@coin_slot, "Failed to process heartbeat")
  end

  private

  def set_coin_slot!
    @coin_slot = current_device
    render_not_found("Coin Slot") if @coin_slot.nil?
  end

  def coin_slot_params
    params.expect(coin_slot: [ :name, :mac_address, :ip_address, :device_id ])
  end

  def coin_slot_update_params
    status = @coin_slot.has_current_active_session? ? :active : :online

    params.expect(coin_slot: [ :mac_address, :ip_address ]).merge(status: status, last_seen_at: Time.current)
  end
end
