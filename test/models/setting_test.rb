require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "validates key uniqueness and presence" do
    setting = Setting.new(key: "", value: "val", value_type: "string")
    assert_not setting.valid?

    duplicate = Setting.new(key: "business_name", value: "Cafe", value_type: "string")
    assert_not duplicate.valid?
  end

  test "validates value_type inclusion" do
    setting = Setting.new(key: "test_key", value: "1", value_type: "invalid_type")
    assert_not setting.valid?

    Setting::VALUE_TYPES.each do |type|
      setting = Setting.new(key: "test_key_#{type}", value: "1", value_type: type)
      assert setting.valid?
    end
  end

  test "set creates or updates setting" do
    assert_difference("Setting.count", 1) do
      Setting.set("new_key", "hello", "string", description: "A new key")
    end

    setting = Setting.find_by(key: "new_key")
    assert_equal "hello", setting.value
    assert_equal "string", setting.value_type
    assert_equal "A new key", setting.description

    assert_no_difference("Setting.count") do
      Setting.set("new_key", "world", "string")
    end
    assert_equal "world", setting.reload.value
  end

  test "get retrieves setting and casts value correctly" do
    Setting.set("str_key", "hello", "string")
    Setting.set("int_key", "123", "integer")
    Setting.set("float_key", "12.34", "float")
    Setting.set("bool_true", "true", "boolean")
    Setting.set("bool_false", "false", "boolean")
    Setting.set("duration_key", "60", "duration")

    assert_equal "hello", Setting.get("str_key")
    assert_equal 123, Setting.get("int_key")
    assert_equal 12.34, Setting.get("float_key")
    assert_equal true, Setting.get("bool_true")
    assert_equal false, Setting.get("bool_false")
    assert_equal 60, Setting.get("duration_key")
  end

  test "get falls back to DEFAULTS when key is not in DB" do
    assert_nil Setting.find_by(key: "minutes_per_credit")
    assert_equal 6, Setting.get("minutes_per_credit") # default value in DEFAULTS
  end

  test "get returns provided default if key is not in DB and default parameter is passed" do
    assert_equal "custom_default", Setting.get("non_existent_key", "custom_default")
  end

  test "shorthand getters cast correctly" do
    Setting.set("test_val", "10", "integer")

    assert_equal "10", Setting.string("test_val")
    assert_equal 10, Setting.integer("test_val")
    assert_equal 10.0, Setting.float("test_val")
    assert_equal 10, Setting.duration("test_val")
  end

  test "exists? check database status" do
    assert Setting.exists?("business_name")
    assert_not Setting.exists?("unknown_setting")
  end

  test "ensure_defaults! seeds missing defaults without overwriting existing settings" do
    # Pre-populate one default with custom value
    Setting.set("business_name", "My Custom Cafe", "string")
    Setting.set("legacy_setting", "obsolete", "string")

    assert_difference("Setting.count", Setting::DEFAULTS.keys.size - 2) do
      Setting.ensure_defaults!
    end

    assert_equal "My Custom Cafe", Setting.get("business_name")
    assert_equal "iCafe", Setting.get("app_name")
    assert_equal 60, Setting.duration("coin_slot_session_duration")
    assert_nil Setting.find_by(key: "legacy_setting")
  end

  test "get handles ActiveRecord::StatementInvalid gracefully" do
    Setting.stub(:find_by, ->(*args) { raise ActiveRecord::StatementInvalid.new("Simulated DB error") }) do
      assert_equal 6, Setting.get("minutes_per_credit")
      assert_equal "custom", Setting.get("unknown_key", "custom")
    end
  end

  test "exists? handles ActiveRecord::StatementInvalid gracefully" do
    Setting.stub(:where, ->(*args) { raise ActiveRecord::StatementInvalid.new("Simulated DB error") }) do
      assert_not Setting.exists?("business_name")
    end
  end
end
