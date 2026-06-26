class AddSecretToCoinSlot < ActiveRecord::Migration[8.1]
  def change
    add_column :coin_slots, :secret, :text
  end
end
