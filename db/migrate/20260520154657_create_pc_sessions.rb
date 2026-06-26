class CreatePcSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :pc_sessions do |t|
      t.references :pc, null: false, foreign_key: true
      t.integer :status, default: 0
      t.integer :total_minutes_purchased
      t.integer :total_minutes_used
      t.datetime :started_at
      t.datetime :expires_at

      t.timestamps
    end
  end
end
