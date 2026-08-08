class RenameEndedAtToExpiresAtInCoinSlotSessions < ActiveRecord::Migration[7.0]
  def change
    rename_column :coin_slot_sessions, :ended_at, :expires_at
  end
end
