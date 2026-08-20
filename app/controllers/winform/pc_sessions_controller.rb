class Winform::PcSessionsController < Winform::BaseController
  before_action :authenticate_device!, :set_pc!
  before_action :set_pc_session!, only: [ :update ]

  def create
    @pc.start_session!

    PcSessions::BroadcastService.call(@pc)

    respond_with_notice(winform_pc_path(@pc.device_id), "Session created to #{ @pc.name }!")
  rescue Pc::NoInsertedCoinsError => e
     respond_with_alert(winform_pc_path(@pc.device_id), e.message)
  rescue ActiveRecord::RecordInvalid => e
    respond_with_alert(winform_pc_path(@pc.device_id), e.record.errors.full_messages)
  end

  def update
    @pc.extend_session!(@pc_session)

    PcSessions::BroadcastService.call(@pc)

    respond_with_notice(winform_pc_path(@pc.device_id), "Session extended to #{@pc.name}!")
  rescue Pc::NoInsertedCoinsError => e
     respond_with_alert(winform_pc_path(@pc.device_id), e.message)
  rescue ActiveRecord::RecordInvalid => e
    respond_with_alert(winform_pc_path(@pc.device_id), e.record.errors.full_messages)
  end

  private

    def set_pc!
      @pc = current_device

      redirect_back fallback_location: error_winform_pcs_path, alert: "PC not found!" if @pc.nil?
    end

    def set_pc_session!
      @pc_session = @pc.active_session

      redirect_back fallback_location: winform_pc_path(@pc&.device_id), alert: "PC session not found!" if @pc_session.nil?
    end
end
