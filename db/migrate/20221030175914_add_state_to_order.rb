class AddStateToOrder < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :state, :integer, :default => 0
    add_column :orders, :buy_type, :integer, :default => 0
  end
end
