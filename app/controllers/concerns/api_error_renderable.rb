# app/controllers/concerns/api_error_renderable.rb
module ApiErrorRenderable
  extend ActiveSupport::Concern

  private

  def render_error(status:, title:, detail:, code: nil, errors: nil, type: nil)
    response = {
      # type: type || "https://api.example.com/errors/#{status}",
      title: title,
      status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status] || status,
      detail: detail,
      instance: request.path,
      trace_id: request.request_id
    }

    response[:code] = code if code
    response[:errors] = errors if errors

    render json: response, status: status
  end

  def render_validation_failed(record, custom_message = nil)
    errors = record.errors.map do |error|
      {
        field: error.attribute,
        code: error.type.upcase,
        message: error.full_message
      }
    end

    render_error(
      status: :unprocessable_content,
      title: "Validation Failed",
      detail: custom_message || "One or more fields failed validation",
      code: "VALIDATION_FAILED",
      errors: errors
    )
  end

  def render_not_found(resource = "Resource")
    render_error(
      status: :not_found,
      title: "Not Found",
      detail: "#{resource} not found",
      code: "NOT_FOUND"
    )
  end

  def render_conflict(detail, code: "CONFLICT")
    render_error(
      status: :conflict,
      title: "Conflict",
      detail: detail,
      code: code
    )
  end

  def render_unauthorized(detail = "Authentication required")
    render_error(
      status: :unauthorized,
      title: "Unauthorized",
      detail: detail,
      code: "UNAUTHORIZED"
    )
  end

  def render_forbidden(detail = "Access denied")
    render_error(
      status: :forbidden,
      title: "Forbidden",
      detail: detail,
      code: "FORBIDDEN"
    )
  end

  def render_internal_error(detail = "An unexpected error occurred")
    render_error(
      status: :internal_server_error,
      title: "Internal Server Error",
      detail: detail,
      code: "INTERNAL_ERROR"
    )
  end
end
