class CreateCoinTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :coin_transactions do |t|
      t.string :transaction_uid
      t.references :coin_slot, null: false, foreign_key: true
      t.references :pc, null: false, foreign_key: true
      t.integer :peso_amount
      t.integer :minutes_granted
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
