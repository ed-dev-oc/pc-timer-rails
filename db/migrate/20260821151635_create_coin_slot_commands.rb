class CreateCoinSlotCommands < ActiveRecord::Migration[8.1]
  def change
    create_table :coin_slot_commands do |t|
      t.references :coin_slot, null: false, foreign_key: true
      t.references :coin_slot_session, null: true, foreign_key: true
      t.integer :action
    end
  end
end
