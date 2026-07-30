class Admin::PcSessionsController < Admin::BaseController
  before_action :set_pc!
  before_action :set_pc_session!, only: [ :stop_session ]

  def create
    @pc.start_manual_session!(pc_session_params)

    respond_with_notice(admin_pc_path(@pc.device_id), "Session created to #{@pc.name}!")
  rescue ActiveRecord::RecordInvalid => e
    respond_with_alert(admin_pc_path(@pc.device_id), e.record.errors.full_messages)
  end

  def stop_session
    result = Pcs::Sessions::Stop.call(@pc, @pc_session)

    if result.success?
      flash[:notice] = "Session stop to #{@pc.name}!"

      redirect_back fallback_location: admin_pc_path(@pc.device_id), status: :moved_permanently
    else
      flash[:alert] = result.error

      redirect_back fallback_location: admin_pc_path(@pc.device_id), status: :unprocessable_entity
    end
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
end
