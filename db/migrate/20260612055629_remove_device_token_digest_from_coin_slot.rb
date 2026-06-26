class RemoveDeviceTokenDigestFromCoinSlot < ActiveRecord::Migration[8.1]
  def change
    remove_column :coin_slots, :device_token_digest, :string
  end
end
