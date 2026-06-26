class CreateCoinSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :coin_slots do |t|
      t.string :mac_address
      t.string :name
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
