class Admin::Pcs::ArchivedController < Admin::BaseController
  before_action :set_pc!

  def create
    @pc.archived!

    Pcs::StatusChangedAction.call(@pc)

    flash[:notice] = "Status set to #{ @pc.status.titleize }."

    redirect_back fallback_location: admin_pc_path(@pc.device_id), status: :moved_permanently
  end

  def destroy
    @pc.unarchived!

    Pcs::StatusChangedAction.call(@pc)

    flash[:notice] = "Status set to #{ @pc.status.titleize }."

    redirect_back fallback_location: admin_pc_path(@pc.device_id), status: :moved_permanently
  end

  private

    def set_pc!
      @pc = Pc.find_by(device_id: params.expect(:id))

      redirect_back fallback_location: admin_pcs_path, alert: "PC not found!", status: :see_other if @pc.nil?
    end
end
