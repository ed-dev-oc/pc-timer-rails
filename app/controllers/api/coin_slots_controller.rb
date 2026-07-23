class Api::CoinSlotsController < Api::BaseController
  before_action :authenticate_device!, :set_coin_slot!, except: [ :register ]

  def register
    @coin_slot = CoinSlot.find_or_initialize_by(device_id: coin_slot_params[:device_id])
    @coin_slot.assign_attributes(
      name: coin_slot_params[:name],
      ip_address: coin_slot_params[:ip_address],
      mac_address: coin_slot_params[:mac_address]
    )
    is_new = @coin_slot.new_record?

    if @coin_slot.save
      response_json = {
        status: is_new ? "created" : "updated",
        coin_slot_id: @coin_slot.id,
        device_id: @coin_slot.device_id,
        secret: @coin_slot.secret
      }

      render json: response_json, status: is_new ? :created : :ok
    else
      render_validation_failed(@coin_slot)
    end
  end

  def heartbeat
    if @coin_slot.update(coin_slot_update_params)
      CoinSlot::Broadcasts::BadgeStatus.call(@coin_slot)

      render json: {
        status: "success",
        message: "Heartbeat received",
        coin_slot_status: @coin_slot.status
      }, status: :ok
    else
      render_validation_failed(@coin_slot, "Failed to process heartbeat")
    end
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
    status = @coin_slot.has_current_active_session? ? :active_session : :active

    params.expect(coin_slot: [ :mac_address, :ip_address ]).merge(status: status, last_seen_at: Time.current)
  end
end
