class Winform::PcsController < Winform::BaseController
  before_action :authenticate_device!, except: [ :error ]
  before_action :set_pc!, :set_pc_session!, only: [ :show, :minimize ]
  before_action :set_coin_slots_active!, :set_coin_slot_session_active!, only: [ :show ]

  def show
  end

  def minimize
  end

  def error
  end

  private

    def set_pc!
      @pc = current_device

      redirect_to error_winform_pcs_path, alert: "PC not registered!" if @pc.nil?
    end

    def set_coin_slot_session_active!
      @coin_slot_session = CoinSlotSession.active.first
    end

    def set_coin_slots_active!
      @coin_slots = CoinSlot.includes(:active_session).where(status: CoinSlot::AUTHORIZED_STATUSES)
    end

    def set_pc_session!
      @pc_session = @pc.active_session
    end
end
