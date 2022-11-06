class AddStateToOrder < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :state, :integer, :default => 0, null: false
    add_column :orders, :buy_type, :integer, :default => 0, null: false
  end
end
