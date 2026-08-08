class Admin::CoinSlotsController < Admin::BaseController
  before_action :set_coin_slot, only: %i[ show destroy restart toggle_lock ]

  # GET /admin/coin_slots or /admin/coin_slots.json
  def index
    @coin_slots = CoinSlot.all
  end

  # GET /admin/coin_slots/1 or /admin/coin_slots/1.json
  def show
    @active_session = @coin_slot.coin_slot_sessions
      .where(status: :active)
      .order(started_at: :desc)
      .first

    @today_transactions = @coin_slot.coin_transactions
      .where(created_at: Time.zone.today.all_day)

    @stats = {
      total_sessions: @coin_slot.coin_slot_sessions.count,
      active_sessions: @coin_slot.coin_slot_sessions.active.count,
      total_minutes: @coin_slot.coin_transactions.sum(:minutes_granted),
      total_income: @coin_slot.coin_transactions.sum(:peso_amount),
      today_income: @today_transactions.sum(:peso_amount),
      total_commands: @coin_slot.esp_command_logs.count
    }

    @coin_transactions = @coin_slot.coin_transactions
      .order(created_at: :desc)
      .limit(20)

    @command_logs = @coin_slot.esp_command_logs
      .order(created_at: :desc)
      .limit(20)

    @coin_slot_sessions = @coin_slot.coin_slot_sessions
      .order(created_at: :desc)
      .limit(10)
  end

  # DELETE /admin/coin_slots/1 or /admin/coin_slots/1.json
  def destroy
    @coin_slot.destroy!

    respond_to do |format|
      format.html { redirect_to admin_coin_slots_path, notice: "Coin slot was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def restart
    @coin_slot.restart!

    CoinSlots::Broadcasts::BadgeStatus.call(@coin_slot)

    flash[:notice] = "Restarting coin slot!"

    redirect_back fallback_location: admin_coin_slot_path(@coin_slot.device_id), status: :moved_permanently
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = e.record.errors.full_messages

    redirect_back fallback_location: admin_coin_slot_path(@coin_slot.device_id), status: :unprocessable_entity
  end

  def toggle_lock
    @coin_slot.toggle_lock!

    CoinSlots::Broadcasts::BadgeStatus.call(@coin_slot)

    flash[:notice] = "Coin slot status changed to #{ status.to_s.titleize }"

    redirect_back fallback_location: admin_coin_slot_path(@coin_slot.device_id), status: :moved_permanently
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = e.record.errors.full_messages

    redirect_back fallback_location: admin_coin_slot_path(@coin_slot.device_id), status: :unprocessable_entity
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_coin_slot
      @coin_slot = CoinSlot.find_by(device_id: params.expect(:id))
    end
end
