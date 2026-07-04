require "test_helper"

class ResultTest < ActiveSupport::TestCase
  test "success creates a successful result" do
    result = Result.success("value")
    assert result.success?
    assert_equal "value", result.value
    assert_nil result.error
  end

  test "failure creates a failed result" do
    result = Result.failure("error message")
    assert_not result.success?
    assert_nil result.value
    assert_equal "error message", result.error
  end

  test "success with nil value is still success" do
    result = Result.success(nil)
    assert result.success?
    assert_nil result.value
  end

  test "failure with nil error is still failure" do
    result = Result.failure(nil)
    assert_not result.success?
    assert_nil result.error
  end
end
