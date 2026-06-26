class RemoveDeviceTokenDigestFromPc < ActiveRecord::Migration[8.1]
  def change
    remove_column :pcs, :device_token_digest, :string
  end
end
