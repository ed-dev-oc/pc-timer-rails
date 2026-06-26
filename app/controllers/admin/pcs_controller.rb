class Admin::PcsController < Admin::BaseController
  before_action :set_pc, only: %i[ show edit update destroy ]

  # GET /admin/pcs or /admin/pcs.json
  def index
    @pcs = Pc.all
  end

  # GET /admin/pcs/1 or /admin/pcs/1.json
  def show
  end

  # GET /admin/pcs/new
  def new
    @pc = Pc.new
  end

  # GET /admin/pcs/1/edit
  def edit
  end

  # POST /admin/pcs or /admin/pcs.json
  def create
    @pc = Pc.new(pc_params)

    respond_to do |format|
      if @pc.save
        format.html { redirect_to [ :admin, @pc ], notice: "Pc was successfully created." }
        format.json { render :show, status: :created, location: @pc }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @pc.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /admin/pcs/1 or /admin/pcs/1.json
  def update
    respond_to do |format|
      if @pc.update(pc_params)
        format.html { redirect_to [ :admin, @pc ], notice: "Pc was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @pc }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @pc.errors, status: :unprocessable_content }
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pc
      @pc = Pc.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def pc_params
      params.expect(pc: [ :name, :ip_address, :mac_address ])
    end
end
