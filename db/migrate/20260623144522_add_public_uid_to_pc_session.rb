class AddPublicUidToPcSession < ActiveRecord::Migration[8.1]
  def change
    add_column :pc_sessions, :public_uid, :string
    add_index :pc_sessions, :public_uid, unique: true
  end
end
