class Winform::PcSessionsController < ApplicationController
  rescue_from Pc::NoInsertedCoinsError, with: :handle_no_inserted_coins
  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid

  before_action :authenticate_device!, :set_pc!
  before_action :set_pc_session!, only: [ :update ]

  def create
    @pc.start_session!

    respond_with_notice(winform_pc_path(@pc.device_id), "Session created to #{ @pc.name }!")
  end

  def update
    result = @pc.extend_session!(@pc_session)

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

    def handle_no_inserted_coins(error)
      respond_with_alert(winform_pc_path(@pc.device_id), error.message)
    end

    def handle_record_invalid(error)
      respond_with_alert(winform_pc_path(@pc.device_id), error.record.errors.full_messages)
    end
end
