class Api::SystemController < Api::BaseController
  def server_time
    render json: { server_time: Time.current.to_i }, status: 200
  end
end
