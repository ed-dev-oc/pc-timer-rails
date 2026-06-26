class AddSecretToPc < ActiveRecord::Migration[8.1]
  def change
    add_column :pcs, :secret, :text
  end
end
