class Admin::CoinSlotsController < Admin::BaseController
  before_action :set_coin_slot, only: %i[ show update destroy restart toggle_lock ]

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

    @sessions = @coin_slot.coin_slot_sessions
      .order(created_at: :desc)
      .limit(10)
  end

  # PATCH/PUT /admin/coin_slots/1 or /admin/coin_slots/1.json
  def update
    respond_to do |format|
      if @coin_slot.update(coin_slot_params)
        format.html { redirect_to [ :admin, @coin_slot ], notice: "Coin slot was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @coin_slot }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @coin_slot.errors, status: :unprocessable_content }
      end
    end
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
    esp_command_log = @coin_slot.esp_command_logs.new(
      command: :restart,
      status: :pending,
      sent_at: Time.current
    )

    if esp_command_log.save
      @coin_slot.offline!
      CoinSlots::Broadcasts::BadgeStatus.call(@coin_slot)

      flash[:notice] = "Restarting coin slot!"

      redirect_back fallback_location: admin_coin_slot_path(@coin_slot.device_id), status: :moved_permanently
    else
      flash[:alert] = esp_command_log.errors.full_messages

      redirect_back fallback_location: admin_coin_slot_path(@coin_slot.device_id), status: :unprocessable_entity
    end
  end

  def toggle_lock
    status = CoinSlot::AUTHORIZED_STATUSES.include?(@coin_slot.status.to_sym) ? :locked : :offline

    if @coin_slot.update(status: status)
      CoinSlots::Broadcasts::BadgeStatus.call(@coin_slot)

      flash[:notice] = "Coin slot status changed to #{ status.to_s.titleize }"

      redirect_back fallback_location: admin_coin_slot_path(@coin_slot.device_id), status: :moved_permanently
    else
      flash[:alert] = @coin_slot.errors.full_messages

      redirect_back fallback_location: admin_coin_slot_path(@coin_slot.device_id), status: :unprocessable_entity
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_coin_slot
      @coin_slot = CoinSlot.find_by(device_id: params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def coin_slot_params
      params.expect(coin_slot: [ :name ])
    end
end
