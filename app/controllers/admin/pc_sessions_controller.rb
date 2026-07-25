class Admin::PcSessionsController < Admin::BaseController
  before_action :set_pc!
  before_action :set_pc_session!, only: [ :stop_session ]

  def create
    pc_session = PcSession.new(pc_session_params)

    result = Pcs::Sessions::CreateManual.call(pc_session)

    if result.success?
      flash[:notice] = "Session created to #{@pc.name}!"

      redirect_back fallback_location: admin_pc_path(@pc.device_id), status: :moved_permanently
    else
      flash[:alert] = result.error

      redirect_back fallback_location: admin_pc_path(@pc.device_id), status: :unprocessable_entity
    end
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
