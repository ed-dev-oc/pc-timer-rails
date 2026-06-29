class Admin::CoinSlotsController < Admin::BaseController
  before_action :set_coin_slot, only: %i[ show edit update destroy ]

  # GET /admin/coin_slots or /admin/coin_slots.json
  def index
    @coin_slots = CoinSlot.all
  end

  # GET /admin/coin_slots/1 or /admin/coin_slots/1.json
  def show
  end

  # GET /admin/coin_slots/new
  def new
    @coin_slot = CoinSlot.new
  end

  # GET /admin/coin_slots/1/edit
  def edit
  end

  # POST /admin/coin_slots or /admin/coin_slots.json
  def create
    @coin_slot = CoinSlot.new(coin_slot_params)

    respond_to do |format|
      if @coin_slot.save
        format.html { redirect_to [ :admin, @coin_slot ], notice: "Coin slot was successfully created." }
        format.json { render :show, status: :created, location: @coin_slot }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @coin_slot.errors, status: :unprocessable_content }
      end
    end
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_coin_slot
      @coin_slot = CoinSlot.find_by(device_id: params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def coin_slot_params
      params.expect(coin_slot: [ :name, :ip_address, :mac_address, :status, :device_id ])
    end
end
