class Setting < ApplicationRecord
  DEFAULTS = {
    'business_name' => 'Internet Cafe',
    'app_name' => 'iCafe',
    'coin_slot_session_duration' => 60,
    'coin_slot_offline_threshold' => 2,
    'minutes_per_credit' => 6,
    'minimum_credit' => 1,
    'pc_offline_threshold' => 2,
    'esp_connection_open_timeout' => 2,
    'esp_connection_timeout' => 5,
    'esp_command_timeout_retry_wait' => 3,
    'esp_command_timeout_max_attempts' => 3,
    'esp_connection_failed_retry_wait' => 5,
    'esp_command_max_attempts' => 3,
    'pc_connection_open_timeout' => 2,
    'pc_connection_timeout' => 5,
    'pc_command_timeout_retry_wait' => 3,
    'pc_command_timeout_max_attempts' => 3,
    'pc_connection_failed_retry_wait' => 5,
    'pc_command_max_attempts' => 3,
    'heartbeat_interval' => 2
  }.freeze

  validates :key, presence: true, uniqueness: true
  validates :value, presence: true
  validates :value_type, presence: true, inclusion: { in: %w[string integer float boolean duration] }

  # Retrieve and cast value based on stored type
  def self.get(key, default = nil)
    setting = find_by(key: key)
    return default_value_for(key, default) unless setting

    cast(setting.value, setting.value_type)
  rescue ActiveRecord::StatementInvalid
    default_value_for(key, default)
  end

  def self.set(key, value, type = 'string', description: nil)
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

  # Helper getters
  def self.string(key, default = nil)   get(key, default) end
  def self.integer(key, default = nil)  cast(get(key, default), 'integer') end
  def self.float(key, default = nil)    cast(get(key, default), 'float') end
  def self.boolean(key, default = nil)  cast(get(key, default), 'boolean') end
  def self.duration(key, default = nil) cast(get(key, default), 'duration') end

  private

  def self.default_value_for(key, default)
    default.nil? ? DEFAULTS[key.to_s] : default
  end

  def self.cast(value, type)
    case type
    when 'string'   then value
    when 'integer'  then value.to_i
    when 'float'    then value.to_f
    when 'boolean'  then ActiveModel::Type::Boolean.new.cast(value)
    when 'duration' then value.to_i # stored as seconds
    else value
    end
  end
end
