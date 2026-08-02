class Admin::PcsController < Admin::BaseController
  before_action :set_pc, only: %i[ show update destroy restart shutdown enable_or_disabled_kiosk kiosk_uninstalled ]

  # GET /admin/pcs or /admin/pcs.json
  def index
    @pcs = Pc.includes(:active_session).all
  end

  # GET /admin/pcs/1 or /admin/pcs/1.json
  def show
    @active_session = @pc.pc_sessions
      .where(status: :active)
      .order(started_at: :desc)
      .first

    @today_transactions = @pc.coin_transactions
      .where(created_at: Time.zone.today.all_day)

    @stats = {
      total_sessions: @pc.pc_sessions.count,
      active_sessions: @pc.pc_sessions.active.count,
      total_minutes: @pc.coin_transactions.sum(:minutes_granted),
      total_income: @pc.coin_transactions.sum(:peso_amount),
      today_income: @today_transactions.sum(:peso_amount),
      total_commands: @pc.pc_command_logs.count
    }

    @coin_transactions = @pc.coin_transactions
      .order(created_at: :desc)
      .limit(20)

    @command_logs = @pc.pc_command_logs
      .order(created_at: :desc)
      .limit(20)

    @pc_sessions = @pc.pc_sessions
      .order(created_at: :desc)
      .limit(10)
  end

  # PATCH/PUT /admin/pcs/1 or /admin/pcs/1.json
  def update
    respond_to do |format|
      if @pc.update(pc_params)
        flash.now[:notice]= "Pc was successfully updated."

        format.turbo_stream
        format.html { redirect_to [ :admin, @pc ], notice: "Pc was successfully updated.", status: :see_other }
      else
        flash.now["alert"] = @pc.errors.full_messages

        format.turbo_stream
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  # DELETE /admin/pcs/1 or /admin/pcs/1.json
  def destroy
    @pc.destroy!

    respond_to do |format|
      format.html { redirect_to admin_pcs_path, notice: "Pc was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def enable_or_disabled_kiosk
    status = @pc.disabled_kiosk? ? :online : :disabled_kiosk

    if @pc.update(status: status)
      Pcs::Broadcasts::BadgeStatus.call(@pc)

      flash[:notice] = "Status set to #{ @pc.status.titleize }."

      redirect_back fallback_location: admin_pc_path(@pc.device_id), status: :moved_permanently
    else
      flash[:alert] = pc_command_log.errors.full_messages

      redirect_back fallback_location: admin_pc_path(@pc.device_id), status: :unprocessable_entity
    end
  end

  def restart
    pc_command_log = PcCommandLog.new(pc: @pc, command: :restart, status: :pending)

    if pc_command_log.save
      flash[:notice] = "Restart PC processing."

      redirect_back fallback_location: admin_pc_path(@pc.device_id), status: :moved_permanently
    else
      flash[:alert] = pc_command_log.errors.full_messages

      redirect_back fallback_location: admin_pc_path(@pc.device_id), status: :unprocessable_entity
    end
  end

  def shutdown
    pc_command_log = PcCommandLog.new(pc: @pc, command: :shutdown, status: :pending)

    if pc_command_log.save
      flash[:notice] = "Shutdown PC processing."

      redirect_back fallback_location: admin_pc_path(@pc.device_id), status: :moved_permanently
    else
      flash[:alert] = pc_command_log.errors.full_messages

      redirect_back fallback_location: admin_pc_path(@pc.device_id), status: :unprocessable_entity
    end
  end

  def kiosk_uninstalled
    if @pc.update(status: :uninstalled)
      Pcs::Broadcasts::BadgeStatus.call(@pc)

      flash[:notice] = "Status set to #{ @pc.status.titleize }."

      redirect_back fallback_location: admin_pc_path(@pc.device_id), status: :moved_permanently
    else
      flash[:alert] = pc_command_log.errors.full_messages

      redirect_back fallback_location: admin_pc_path(@pc.device_id), status: :unprocessable_entity
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pc
      @pc = Pc.includes(
        :pc_sessions,
        :coin_transactions,
        :pc_command_logs
      ).find_by(device_id: params.expect(:id))

      redirect_back fallback_location: admin_pcs_path, alert: "PC not found!", status: :see_other if @pc.nil?
    end

    # Only allow a list of trusted parameters through.
    def pc_params
      params.expect(pc: [ :name ])
    end
end
