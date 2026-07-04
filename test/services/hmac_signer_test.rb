require "test_helper"

class HmacSignerTest < ActiveSupport::TestCase
  setup do
    @secret = "super-secret-key"
    @method = "POST"
    @path = "/api/pcs/register"
    @timestamp = 1716160000
    @body = '{"name":"PC One"}'
  end

  test "generates deterministic hmac signature" do
    sig1 = HmacSigner.sign(@secret, @method, @path, @timestamp, @body)
    sig2 = HmacSigner.sign(@secret, @method, @path, @timestamp, @body)

    assert_equal sig1, sig2
    assert_match(/\A[0-9a-f]{64}\z/, sig1)
  end

  test "signature changes when secret changes" do
    sig1 = HmacSigner.sign(@secret, @method, @path, @timestamp, @body)
    sig2 = HmacSigner.sign("different-secret", @method, @path, @timestamp, @body)

    assert_not_equal sig1, sig2
  end

  test "signature changes when method changes" do
    sig1 = HmacSigner.sign(@secret, @method, @path, @timestamp, @body)
    sig2 = HmacSigner.sign(@secret, "GET", @path, @timestamp, @body)

    assert_not_equal sig1, sig2
  end

  test "signature changes when path changes" do
    sig1 = HmacSigner.sign(@secret, @method, @path, @timestamp, @body)
    sig2 = HmacSigner.sign(@secret, @method, "/other/path", @timestamp, @body)

    assert_not_equal sig1, sig2
  end

  test "signature changes when timestamp changes" do
    sig1 = HmacSigner.sign(@secret, @method, @path, @timestamp, @body)
    sig2 = HmacSigner.sign(@secret, @method, @path, @timestamp + 1, @body)

    assert_not_equal sig1, sig2
  end

  test "signature changes when body changes" do
    sig1 = HmacSigner.sign(@secret, @method, @path, @timestamp, @body)
    sig2 = HmacSigner.sign(@secret, @method, @path, @timestamp, '{"name":"PC Two"}')

    assert_not_equal sig1, sig2
  end

  test "handles empty body" do
    sig = HmacSigner.sign(@secret, "GET", @path, @timestamp, "")
    assert sig.present?
  end
end
