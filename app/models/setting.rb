class Setting < ApplicationRecord
  DEFAULTS = {
    "business_name" => "Internet Cafe",
    "app_name" => "iCafe",
    "coin_slot_session_duration" => 60,
    "coin_slot_offline_threshold" => 2,
    "minutes_per_credit" => 6,
    "minimum_credit" => 1,
    "pc_offline_threshold" => 2,
    "esp_connection_open_timeout" => 2,
    "esp_connection_timeout" => 5,
    "esp_command_timeout_retry_wait" => 3,
    "esp_command_timeout_max_attempts" => 3,
    "esp_connection_failed_retry_wait" => 5,
    "esp_command_max_attempts" => 3,
    "pc_connection_open_timeout" => 2,
    "pc_connection_timeout" => 5,
    "pc_command_timeout_retry_wait" => 3,
    "pc_command_timeout_max_attempts" => 3,
    "pc_connection_failed_retry_wait" => 5,
    "pc_command_max_attempts" => 3,
    "heartbeat_interval" => 2
  }.freeze

  DEFAULT_TYPES = {
    "business_name" => "string",
    "app_name" => "string",
    "coin_slot_session_duration" => "duration"
  }.freeze

  DEFAULT_DESCRIPTIONS = {
    "business_name" => "Business display name",
    "app_name" => "Application name",
    "coin_slot_session_duration" => "Coin slot session duration in seconds",
    "coin_slot_offline_threshold" => "Coin slot offline threshold in minutes",
    "minutes_per_credit" => "Minutes granted per credit",
    "minimum_credit" => "Minimum credit amount per transaction",
    "pc_offline_threshold" => "PC offline threshold in minutes",
    "esp_connection_open_timeout" => "ESP connection open timeout in seconds",
    "esp_connection_timeout" => "ESP request timeout in seconds",
    "esp_command_timeout_retry_wait" => "ESP command timeout retry wait in seconds",
    "esp_command_timeout_max_attempts" => "ESP command timeout max attempts",
    "esp_connection_failed_retry_wait" => "ESP command connection failure retry wait in seconds",
    "esp_command_max_attempts" => "ESP command connection failure max attempts",
    "pc_connection_open_timeout" => "PC agent connection open timeout in seconds",
    "pc_connection_timeout" => "PC agent request timeout in seconds",
    "pc_command_timeout_retry_wait" => "PC command timeout retry wait in seconds",
    "pc_command_timeout_max_attempts" => "PC command timeout max attempts",
    "pc_connection_failed_retry_wait" => "PC command connection failure retry wait in seconds",
    "pc_command_max_attempts" => "PC command connection failure max attempts",
    "heartbeat_interval" => "Heartbeat interval in minutes"
  }.freeze

  VALUE_TYPES = %w[string integer float boolean duration].freeze
  ADVANCED_KEYS = %w[
    esp_connection_open_timeout
    esp_connection_timeout
    esp_command_timeout_retry_wait
    esp_command_timeout_max_attempts
    esp_connection_failed_retry_wait
    esp_command_max_attempts
    pc_connection_open_timeout
    pc_connection_timeout
    pc_command_timeout_retry_wait
    pc_command_timeout_max_attempts
    pc_connection_failed_retry_wait
    pc_command_max_attempts
    heartbeat_interval
  ].freeze

  validates :key, presence: true, uniqueness: true
  validates :value, presence: true
  validates :value_type, presence: true, inclusion: { in: VALUE_TYPES }

  # Retrieve and cast value based on stored type
  def self.get(key, default = nil)
    setting = find_by(key: key)
    return default_value_for(key, default) unless setting

    cast(setting.value, setting.value_type)
  rescue ActiveRecord::StatementInvalid
    default_value_for(key, default)
  end

  def self.set(key, value, type = "string", description: nil)
    setting = find_or_initialize_by(key: key)
    setting.value = value.to_s
    setting.value_type = type
    setting.description = description if description
    setting.save!
    setting
  end

  def self.exists?(key = :none)
    return super() if key == :none
    return super(key) unless key.is_a?(String) || key.is_a?(Symbol)

    where(key: key).exists?
  rescue ActiveRecord::StatementInvalid
    false
  end

  def self.ensure_defaults!
    DEFAULTS.each do |key, value|
      setting = find_or_initialize_by(key: key)
      setting.value = value.to_s if setting.new_record?
      setting.value_type = DEFAULT_TYPES.fetch(key, "integer") if setting.new_record?
      setting.description = DEFAULT_DESCRIPTIONS[key] if setting.description.blank?
      setting.save!
    end
  end

  # Helper getters
  def self.string(key, default = nil)
  setting = find_by(key: key)
  return default if setting.nil?
  setting.value
end
  def self.integer(key, default = nil)  cast(get(key, default), "integer") end
  def self.float(key, default = nil)    cast(get(key, default), "float") end
  def self.boolean(key, default = nil)  cast(get(key, default), "boolean") end
  def self.duration(key, default = nil) cast(get(key, default), "duration") end

  private

  def self.default_value_for(key, default)
    default.nil? ? DEFAULTS[key.to_s] : default
  end

  def self.cast(value, type)
    case type
    when "string"   then value
    when "integer"  then value.to_i
    when "float"    then value.to_f
    when "boolean"  then ActiveModel::Type::Boolean.new.cast(value)
    when "duration" then value.to_i # stored as seconds
    else value
    end
  end
end
