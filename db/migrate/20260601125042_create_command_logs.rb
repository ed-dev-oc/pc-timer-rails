class CreateCommandLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :command_logs do |t|
      t.string :type
      t.integer :status
      t.integer :command
      t.string :error_message
      t.datetime :sent_at
      t.datetime :executed_at
      t.references :pc, null: true, foreign_key: true
      t.references :coin_slot, null: true, foreign_key: true

      t.timestamps
    end
  end
end
