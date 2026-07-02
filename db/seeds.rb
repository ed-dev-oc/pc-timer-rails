# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

User.find_or_create_by(email: "admin@admin.com") do |user|
  user.password = "admin123"
  user.password_confirmation = "admin123"
  user.role = :admin
end

Setting.set('business_name', 'Internet Cafe', 'string', description: 'Business display name')
Setting.set('app_name', 'iCafe', 'string', description: 'Application name')
Setting.set('coin_slot_session_duration', 60, 'duration', description: 'Coin slot session duration in seconds')
Setting.set('coin_slot_offline_threshold', 2, 'integer', description: 'Coin slot offline threshold in minutes')
Setting.set('minutes_per_credit', 6, 'integer', description: 'Minutes granted per credit')
Setting.set('minimum_credit', 1, 'integer', description: 'Minimum credit amount per transaction')
Setting.set('pc_offline_threshold', 2, 'integer', description: 'PC offline threshold in minutes')
Setting.set('esp_connection_open_timeout', 2, 'integer', description: 'ESP connection open timeout in seconds')
Setting.set('esp_connection_timeout', 5, 'integer', description: 'ESP request timeout in seconds')
Setting.set('esp_command_timeout_retry_wait', 3, 'integer', description: 'ESP command timeout retry wait in seconds')
Setting.set('esp_command_timeout_max_attempts', 3, 'integer', description: 'ESP command timeout max attempts')
Setting.set('esp_connection_failed_retry_wait', 5, 'integer', description: 'ESP command connection failure retry wait in seconds')
Setting.set('esp_command_max_attempts', 3, 'integer', description: 'ESP command connection failure max attempts')
Setting.set('pc_connection_open_timeout', 2, 'integer', description: 'PC agent connection open timeout in seconds')
Setting.set('pc_connection_timeout', 5, 'integer', description: 'PC agent request timeout in seconds')
Setting.set('pc_command_timeout_retry_wait', 3, 'integer', description: 'PC command timeout retry wait in seconds')
Setting.set('pc_command_timeout_max_attempts', 3, 'integer', description: 'PC command timeout max attempts')
Setting.set('pc_connection_failed_retry_wait', 5, 'integer', description: 'PC command connection failure retry wait in seconds')
Setting.set('pc_command_max_attempts', 3, 'integer', description: 'PC command connection failure max attempts')
Setting.set('heartbeat_interval', 2, 'integer', description: 'Heartbeat interval in minutes')
