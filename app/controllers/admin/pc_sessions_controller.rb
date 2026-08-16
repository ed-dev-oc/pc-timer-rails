class Admin::PcSessionsController < Admin::BaseController
  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid

  before_action :set_pc!
  before_action :set_pc_session!, only: [ :stop_session ]

  def create
    @pc.start_manual_session!(pc_session_params)

    PcSessions::BroadcastService.call(@pc)

    respond_with_notice(admin_pc_path(@pc.device_id), "Session created to #{@pc.name}!")
  end

  def stop_session
    @pc.stop_session!(@pc_session)

    PcSessions::BroadcastService.call(@pc)

    respond_with_notice(admin_pc_path(@pc.device_id), "Session stop to #{@pc.name}!")
  end

  private

    def set_pc!
      @pc = Pc.find_by(device_id: params[:pc_id])

      redirect_back fallback_location: admin_pcs_path, alert: "PC not found!", status: :see_other if @pc.nil?
    end

    def set_pc_session!
      @pc_session = PcSession.find_by(public_uid: params[:id])

      redirect_back fallback_location: admin_pc_path(@pc), alert: "PC session not found!", status: :see_other if @pc_session.nil?
    end

    def pc_session_params
      params.expect(pc_session: [ :total_minutes_purchased ]).merge(pc_id: @pc.id)
    end

    def handle_record_invalid(error)
      respond_with_alert(admin_pc_path(@pc.device_id), error.record.errors.full_messages)
    end
end
