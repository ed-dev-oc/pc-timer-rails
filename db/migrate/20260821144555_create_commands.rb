class CreateCommands < ActiveRecord::Migration[8.1]
  def change
    create_table :commands do |t|
      t.references :commandable, polymorphic: true, null: false
      t.string :error_message
      t.datetime :sent_at
      t.datetime :executed_at
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
