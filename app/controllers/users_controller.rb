class UsersController < ApplicationController
  before_action :authenticate_user!
  layout :resolve_layout

  def settings
    @user = current_user
  end

  def update
    @user = current_user
    params_to_update = user_params.to_h

    if params_to_update[:password].blank? && params_to_update[:password_confirmation].blank?
      params_to_update.delete(:password)
      params_to_update.delete(:password_confirmation)
    end

    if @user.update(params_to_update)
      bypass_sign_in(@user)
      redirect_to settings_path, notice: "Account settings updated successfully."
    else
      render :settings, status: :unprocessable_entity
    end
  end

  private

  def resolve_layout
    if current_user&.admin?
      "admin"
    else
      "application"
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def authenticate_user!
    unless current_user
      redirect_to new_user_session_path, alert: "Please sign in to view this page."
    end
  end
end
