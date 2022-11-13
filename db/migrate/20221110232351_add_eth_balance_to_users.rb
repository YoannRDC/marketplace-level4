class AddEthBalanceToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :eth_balance, :decimal, :precision => 15, :scale => 8, :default => 0, null: false
  end
end
