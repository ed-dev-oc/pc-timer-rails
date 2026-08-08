class AddEndedAtToSessions < ActiveRecord::Migration[7.0]
  def change
    # Add nullable datetime column ended_at to pc_sessions unless it already exists
    add_column :pc_sessions, :ended_at, :datetime, default: nil, if_not_exists: true

    # Add nullable datetime column ended_at to coin_slot_sessions unless it already exists
    add_column :coin_slot_sessions, :ended_at, :datetime, default: nil, if_not_exists: true
  end
end
