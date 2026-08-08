class CreateCoinSlotSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :coin_slot_sessions do |t|
      t.references :coin_slot, null: false, foreign_key: true
      t.references :pc, null: false, foreign_key: true
      t.integer :status, default: 0
      t.datetime :started_at
      t.datetime :expires_at

      t.timestamps
    end
  end
end
