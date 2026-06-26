class AddDeviceFieldsToCoinSlots < ActiveRecord::Migration[8.1]
  def change
    add_column :coin_slots, :device_id, :string
    add_column :coin_slots, :device_token_digest, :string
    add_column :coin_slots, :last_seen_at, :datetime

    add_index :coin_slots, :device_id, unique: true
    add_index :coin_slots, :device_token_digest, unique: true
  end
end
