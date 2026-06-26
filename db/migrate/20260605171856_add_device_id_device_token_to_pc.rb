class AddDeviceIdDeviceTokenToPc < ActiveRecord::Migration[8.1]
  def change
    add_column :pcs, :device_id, :string
    add_index :pcs, :device_id, unique: true
    add_column :pcs, :device_token_digest, :string
    add_index :pcs, :device_token_digest, unique: true
  end
end
