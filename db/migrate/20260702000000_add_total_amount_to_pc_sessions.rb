class AddTotalAmountToPcSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :pc_sessions, :total_amount, :integer, default: 0, null: false
  end
end
