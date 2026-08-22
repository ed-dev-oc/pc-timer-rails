class CreatePcCommands < ActiveRecord::Migration[8.1]
  def change
    create_table :pc_commands do |t|
      t.references :pc, null: false, foreign_key: true
      t.integer :action
    end
  end
end
