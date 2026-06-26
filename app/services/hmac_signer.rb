class HmacSigner
  def self.sign(secret, method, path, timestamp, body)
    payload = [
      method,
      path,
      timestamp,
      body
    ].join("|")

    OpenSSL::HMAC.hexdigest(
      "SHA256",
      secret,
      payload
    )
  end
end
