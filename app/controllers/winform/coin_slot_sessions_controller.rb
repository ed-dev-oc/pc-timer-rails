class Winform::CoinSlotSessionsController < ApplicationController
  before_action :authenticate_device!, :set_pc!
  before_action :set_coin_slot!, only: [ :create ]
  before_action :set_coin_slot_session!, only: [ :cancel ]

  def create
    result = CreateCoinSlotSession.call(@pc, @coin_slot)

    if result.success?
      flash.now[:notice] = "Insert coin to #{ @coin_slot.name }!"

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: winform_pc_path(@pc.device_id), notice: "Insert coin now!" }
      end
    else
      flash.now[:alert] = result.error

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: winform_pc_path(@pc.device_id), alert: result.error }
      end
    end
  end

  def cancel
    if @coin_slot_session.mark_inactive_and_disable_esp!
      @coin_slot = @coin_slot_session.coin_slot.reload

      flash.now[:notice] = "Cancel success!"

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: winform_pc_path(@pc.device_id), notice: "Insert coin now!" }
      end
    else
      flash.now[:alert] = @coin_slot_session.errors.full_messages.join(", ")

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: winform_pc_path(@pc.device_id), alert: @coin_slot_session.errors.full_messages.join(", ") }
      end
    end
  end

  private

    def set_pc!
      @pc = current_device

      redirect_to error_winform_pcs_path, alert: "PC not registered!" if @pc.nil?
    end

    def set_coin_slot!
      @coin_slot = CoinSlot.includes(:active_coin_slot_session).where(status: [ :active ]).first

      redirect_to winform_pc_path(@pc.device_id), alert: "No coin slot found!" if @coin_slot.nil?
    end

    def set_coin_slot_session!
      @coin_slot_session = @pc.active_coin_slot_session

      redirect_to winform_pc_path(@pc.device_id), alert: "No coin slot session active found!" if @coin_slot_session.nil?
    end
end
