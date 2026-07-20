class Admin::SettingsController < Admin::BaseController
  before_action :ensure_default_settings

  def show
    load_settings
  end

  def update
    Setting.transaction do
      update_settings.each do |id, attributes|
        setting = Setting.find(id)
        setting.update!(attributes.slice("value"))
      end
    end

    redirect_to admin_settings_path, notice: "Settings were successfully updated.", status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    load_settings
    flash.now[:alert] = error.record.errors.full_messages
    render :show, status: :unprocessable_content
  end

  private

    def ensure_default_settings
      Setting.ensure_defaults!
    end

    def load_settings
      @settings = Setting.order(:key)
      @basic_settings = @settings.reject { |setting| Setting::ADVANCED_KEYS.include?(setting.key) }
      @advanced_settings = @settings.select { |setting| Setting::ADVANCED_KEYS.include?(setting.key) }
    end

    def update_settings
      # Permit only known setting keys to avoid mass assignment vulnerabilities.
      # Combine default setting keys and advanced keys defined in the Setting model.
      allowed_keys = Setting::DEFAULTS.keys + Setting::ADVANCED_KEYS
      params.fetch(:settings, ActionController::Parameters.new).permit(allowed_keys).to_h
    end
end
