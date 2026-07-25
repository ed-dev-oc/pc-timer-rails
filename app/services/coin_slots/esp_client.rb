module CoinSlots
  class EspClient
    def initialize(coin_slot)
      @coin_slot = coin_slot

      @connection = Faraday.new(
        url: "http://#{@coin_slot.ip_address}"
      ) do |f|
        f.request :url_encoded
        f.options.open_timeout = Setting.integer("esp_connection_open_timeout")
        f.options.timeout = Setting.integer("esp_connection_timeout")
        f.response :logger
        f.adapter Faraday.default_adapter
      end
    end

    def enable(coin_slot_session)
      pc = coin_slot_session.pc

      params = {
        ended_at: coin_slot_session.ended_at.to_i,
        pc_name: pc.name,
        session_uid: coin_slot_session.public_uid
      }.compact

      post("/coin/enable", params)
    end

    def disable(coin_slot_session)
      params = {
        session_uid: coin_slot_session.public_uid
      }.compact

      post("/coin/disable", params)
    end

    def restart
      post("/reboot")
    end

    private

    def post(path, params = {})
      timestamp = Time.current.to_i
      signature = HmacSigner.sign(
        @coin_slot.secret,
        "SERVER",
        path,
        timestamp,
        URI.encode_www_form(params)
      )

      response = @connection.post(path, params) do |req|
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
