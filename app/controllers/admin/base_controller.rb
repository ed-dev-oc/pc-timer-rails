class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin!
  layout "admin"

  private

  def authenticate_admin!
    unless current_user&.admin? || current_user&.role == "admin"
      redirect_to root_path, alert: "Access denied."
    end
  end
end
