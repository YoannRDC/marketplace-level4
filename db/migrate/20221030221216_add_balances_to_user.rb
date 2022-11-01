class AddBalancesToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :eur_balance, :decimal, :precision => 11, :scale => 2, :default => 0
    add_column :users, :btc_balance, :decimal, :precision => 15, :scale => 8, :default => 0
  end
end
