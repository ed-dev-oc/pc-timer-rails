class AddIpAddressToCoinSlot < ActiveRecord::Migration[8.1]
  def change
    add_column :coin_slots, :ip_address, :string
  end
end
