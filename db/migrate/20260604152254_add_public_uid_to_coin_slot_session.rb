class AddPublicUidToCoinSlotSession < ActiveRecord::Migration[8.1]
  def change
    add_column :coin_slot_sessions, :public_uid, :string
  end
end
