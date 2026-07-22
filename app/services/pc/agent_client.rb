class Pc
  class AgentClient
    def initialize(pc)
      @pc = pc

      @connection = Faraday.new(
        url: "http://#{pc.ip_address}:5000"
      ) do |f|
        f.options.open_timeout = Setting.integer("pc_connection_open_timeout")
        f.options.timeout = Setting.integer("pc_connection_timeout")
      end
    end

    def restart
      post("/api/system/restart")
    end

    def shutdown
      post("/api/system/shutdown")
    end

    def lock
      post("/api/kiosk/lock")
    end

    def unlock
      pc_session = @pc.active_pc_session

      session_json = pc_session.present? ? {
        id: pc_session&.public_uid,
        status: pc_session&.status,
        expires_at_utc: pc_session&.expires_at&.utc
      } : nil

      body = {
        session: session_json,
        last_server_time: Time.current.utc
      }

      post("/api/kiosk/unlock", body)
    end

    private

    def post(path, body = {})
      timestamp = Time.current.to_i
      signature = HmacSigner.sign(
        @pc.secret,
        "POST",
        path,
        timestamp,
        body.to_json
      )

      response = @connection.post(path, body.to_json) do |req|
        req.headers["X-SIGNATURE"] = signature.to_s
        req.headers["X-TIMESTAMP"] = timestamp.to_s
      end

      # ❗ IMPORTANT: FORCE FAILURE TO RAISE EXCEPTION
      unless response.success?
        raise Faraday::ConnectionFailed, "HTTP #{response.status}"
      end

      { status: "success" }
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      # re-raise so ActiveJob retry works
      raise e
    end
  end
end
