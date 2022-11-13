class AddEthToOrder < ActiveRecord::Migration[7.0]
  def change
    rename_column :orders, :price_per_btc, :price_per_coin
    rename_column :orders, :btc_amount, :coin_amount
    add_column :orders, :coin, :integer, :default => 0, null: false
  end
end
