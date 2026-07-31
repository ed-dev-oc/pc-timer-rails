class Winform::CoinSlotSessionsController < ApplicationController
  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid

  before_action :authenticate_device!, :set_pc!
  before_action :set_coin_slot!, only: [ :create ]
  before_action :set_active_coin_slot, only: [ :cancel ]

  def create
    @coin_slot.start_session!(@pc)

    respond_with_notice(winform_pc_path(@pc.device_id), "Insert coin to #{ @coin_slot.name }!")
  end

  def cancel
    @coin_slot.stop_session!

    respond_with_notice(winform_pc_path(@pc.device_id), "Cancel success!")
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

    def set_active_coin_slot
      @coin_slot = @pc.active_coin_slot

      redirect_to winform_pc_path(@pc.device_id), alert: "No coin slot session active found!" if @coin_slot.nil?
    end

    def handle_record_invalid(error)
      respond_with_alert(winform_pc_path(@pc.device_id), error.record.errors.full_messages)
    end
end
