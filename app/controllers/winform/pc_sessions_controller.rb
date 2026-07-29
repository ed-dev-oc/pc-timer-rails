class Winform::PcSessionsController < ApplicationController
  before_action :authenticate_device!, :set_pc!
  before_action :set_pc_session!, only: [ :update ]
  def create
    result = Pcs::Sessions::Start.call(@pc)

    if result.success?
      flash.now[:notice] = "Session created to #{@pc.name}!"

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: winform_pc_path(@pc.device_id), notice: "Session created to #{@pc.name}!" }
      end
    else
      flash.now[:alert] = result.error

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: winform_pc_path(@pc.device_id), alert: result.error }
      end
    end
  end

  def update
    result = Pcs::Sessions::Extend.call(@pc, @pc_session)

    if result.success?
      flash.now[:notice] = "Session extended to #{@pc.name}!"

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: winform_pc_path(@pc.device_id), notice: "Session created to #{@pc.name}!" }
      end
    else
      flash.now[:alert] = result.error

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: winform_pc_path(@pc.device_id), alert: result.error }
      end
    end
  end

  private

    def set_pc!
      @pc = current_device

      redirect_back fallback_location: error_winform_pcs_path, alert: "PC not found!" if @pc.nil?
    end

    def set_pc_session!
      @pc_session = @pc.active_pc_session

      redirect_back fallback_location: winform_pc_path(@pc&.device_id), alert: "PC session not found!" if @pc_session.nil?
    end
end
