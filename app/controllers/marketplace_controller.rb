class MarketplaceController < ApplicationController
  def index
    @orders = Order.all.order('price_per_btc DESC')

    @sells = @orders.select{|o| o.side == "sell" && o.state != "filled"}
    @buys = @orders.select{|o| o.side == "buy" && o.state != "filled"}
    @filled = @orders.select{|o| o.state == "filled"}

    if (@sells.count != 0 && @buys.count != 0)
      @avg_price = (@sells.last.price_per_btc + @buys.first.price_per_btc)/2
    end

    @total_market_eur = User.all.pluck(:eur_balance).reduce(&:+)
    @total_market_btc = User.all.pluck(:btc_balance).reduce(&:+)

    @users = User.all
  end
end
