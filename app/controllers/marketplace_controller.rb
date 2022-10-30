class MarketplaceController < ApplicationController
  def index
    @orders = Order.all.order('price_per_btc DESC')

    @sells = @orders.select{|o| o.side == "sell"}
    @buys = @orders.select{|o| o.side == "buy"}

    @avg_price = (@sells.last.price_per_btc + @buys.first.price_per_btc)/2

  end
end
