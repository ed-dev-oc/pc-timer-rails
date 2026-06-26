class CreatePcs < ActiveRecord::Migration[8.1]
  def change
    create_table :pcs do |t|
      t.string :name
      t.string :ip_address
      t.string :mac_address
      t.integer :status, default: 0
      t.datetime :last_seen_at

      t.timestamps
    end
  end
end
