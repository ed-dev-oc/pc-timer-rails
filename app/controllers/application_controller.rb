class ApplicationController < ActionController::Base
  include ApiErrorRenderable

  helper_method :current_device

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  # stale_when_importmap_changes

  def current_device
    @current_device
  end

  def authenticate_device!
    device_id   = request.headers["X-DEVICE-ID"]
    signature = request.headers["X-SIGNATURE"]
    timestamp = request.headers["X-TIMESTAMP"]
    method = request.method
    path = request.path
    body = request.raw_post

    return render_unauthorized("Missing headers") if device_id.blank? || signature.blank?

    device = Pc.find_by(device_id: device_id) || CoinSlot.find_by(device_id: device_id)

    return render_unauthorized("Missing device") if device.nil?
    return render_unauthorized("Invalid device") unless device&.authorized_status?

    # optional: replay protection (5 min window)
    if timestamp.present?
      return render_unauthorized("Expired request") if (Time.current.to_i - timestamp.to_i).abs > 300
    end

    expected_signature = HmacSigner.sign(device.secret, method, path, timestamp, body)

    unless ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
      return render_unauthorized("Invalid signature")
    end

    @current_device = device
    device.update(last_seen_at: Time.current)
  end

  protected

    def after_sign_in_path_for(resource)
      stored_location_for(resource) ||
        if resource.admin?
          admin_root_path
        else
          root_path
        end
    end

    def after_sign_out_path_for(resource_or_scope)
      new_user_session_path
    end

    def respond_with_notice(path, message)
      flash.now[:notice] = message

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: path, notice: message }
      end
    end

    def respond_with_alert(path, message)
      flash.now[:alert] = message

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: path, alert: message }
      end
    end
end
