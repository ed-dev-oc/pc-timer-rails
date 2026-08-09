class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin!
  layout "admin"

  private

  def authenticate_admin!
    unless [ "owner", "admin" ].any?(current_user&.role)
      redirect_to root_path, alert: "Access denied."
    end
  end
end
