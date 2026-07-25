class Api::PcsController < Api::BaseController
  before_action :authenticate_device!, :set_pc!, except: [ :register ]

  def register
    @pc = Pc.find_or_initialize_by(
      device_id: pc_params[:device_id]
    )

    @pc.assign_attributes(
      name: pc_params[:name],
      ip_address: pc_params[:ip_address],
      mac_address: pc_params[:mac_address],
      status: :online
    )

    is_new = @pc.new_record?

    if @pc.save
      render json: {
        status: is_new ? "created" : "updated",
        pc_id: @pc.id,
        device_id: @pc.device_id,
        secret: @pc.secret
      }, status: is_new ? :created : :ok
    else
      render_validation_failed(@pc)
    end
  end

  def signin
    pc_session = @pc.active_pc_session
    pc_status = @pc.status

    unless @pc.disabled_kiosk?
      pc_status = pc_session.present? ? :active_session : :online
    end

    if @pc.update(status: pc_status)
      Pcs::Broadcasts::BadgeStatus.call(@pc)

      render json: {
        status: "success",
        message: "Online status set"
      }, status: :ok
    else
      render_validation_failed(@pc, "Failed to set online status")
    end
  end

  def signout
    if @pc.update(status: :offline, last_seen_at: Time.current)
      Pcs::Broadcasts::BadgeStatus.call(@pc)

      render json: {
        status: "success",
        message: "Offline status set"
      }, status: :ok
    else
      render_validation_failed(@pc, "Failed to set offline status")
    end
  end

  def heartbeat
    if @pc.update(pc_update_params)
      Pcs::Broadcasts::BadgeStatus.call(@pc)

      pc_session = @pc.active_pc_session

      session_json = pc_session.present? ? {
        id: pc_session&.public_uid,
        status: pc_session&.status,
        expires_at_utc: pc_session&.expires_at&.utc
      } : nil

      render json: {
        status: "success",
        message: "Heartbeat received",
        pc: {
          status: @pc.status
        },
        session: session_json,
        last_server_time: Time.current.utc
      }
    else
      render_validation_failed(@pc, "Failed to process heartbeat")
    end
  end

  def session_status
    pc_session = @pc.active_pc_session

    session_json = pc_session.present? ? {
      id: pc_session&.public_uid,
      status: pc_session&.status,
      expires_at_utc: pc_session&.expires_at&.utc
    } : nil

    render json: {
      pc_status: @pc.status,
      session: session_json,
      last_server_time: Time.current.utc
    }, status: :ok
  end

  private

    def set_pc!
      @pc = current_device

      render_not_found("PC") if @pc.nil?
    end

    def pc_params
      params.expect(pc: [ :name, :mac_address, :ip_address, :device_id ])
    end

    def pc_update_params
      status = @pc.status

      unless @pc.disabled_kiosk?
        status = @pc.active_pc_session.present? ? :active_session : :online
      end

      params.expect(pc: [ :mac_address, :ip_address ]).merge(status: status)
    end
end
