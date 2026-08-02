class Api::PcsController < Api::BaseController
  before_action :authenticate_device!, :set_pc!, except: [ :register ]

  def register
    @pc = Pc.register!(params)

    render json: {
      status: "success",
      pc_id: @pc.id,
      device_id: @pc.device_id,
      secret: @pc.secret
    }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render_validation_failed(e.record)
  end

  def signin
    @pc.signin!

    render json: {
      status: "success",
      message: "Online status set"
    }, status: :ok
  rescue ActiveRecord::RecordInvalid
    render_validation_failed(@pc, "Failed to set online status")
  end

  def signout
    @pc.signout!

    render json: {
      status: "success",
      message: "Offline status set"
    }, status: :ok
  rescue ActiveRecord::RecordInvalid
    render_validation_failed(@pc, "Failed to set offline status")
  end

  def heartbeat
    @pc.receive_heartbeat!(pc_update_params)

    render json: {
      status: "success",
      message: "Heartbeat received",
      pc: {
        status: @pc.status
      },
      session: @pc.active_session_json,
      last_server_time: Time.current.utc
    }
  rescue ActiveRecord::RecordInvalid
    render_validation_failed(@pc, "Failed to process heartbeat")
  end

  def session_status
    render json: {
      pc_status: @pc.status,
      session: @pc.active_session_json,
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
        status = @pc.active_session.present? ? :active : :online
      end

      params.expect(pc: [ :mac_address, :ip_address ]).merge(status: status)
    end
end
