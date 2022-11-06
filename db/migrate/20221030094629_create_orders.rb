class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.decimal :price_per_btc, :precision => 11, :scale => 2, null: false
      t.decimal :btc_amount, :precision => 15, :scale => 8, null: false
      t.integer :side, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
