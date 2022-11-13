class MarketplaceController < ApplicationController

  def index
    @orders = Order.all.order('price_per_coin DESC')

    # tables orders BTC
    @sells_btc = @orders.select{|o| o.side == "sell" && o.state != "filled" && o.coin == 'BTC'}
    @buys_btc = @orders.select{|o| o.side == "buy" && o.state != "filled" && o.coin == 'BTC'}

    # tables orders ETH
    @sells_eth = @orders.select{|o| o.side == "sell" && o.state != "filled" && o.coin == 'ETH'}
    @buys_eth = @orders.select{|o| o.side == "buy" && o.state != "filled" && o.coin == 'ETH'}
    @filled = @orders.select{|o| o.state == "filled"}

    # average price BTC
    if (@sells_btc.count != 0 && @buys_btc.count != 0)
      @avg_price_btc = (@sells_btc.last.price_per_coin + @buys_btc.first.price_per_coin)/2
    end

    # average price ETH 
    if (@sells_eth.count != 0 && @buys_eth.count != 0)
      @avg_price_eth = (@sells_eth.last.price_per_coin + @buys_eth.first.price_per_coin)/2
    end

    @total_market_eur = User.all.pluck(:eur_balance).reduce(&:+)
    @total_market_btc = User.all.pluck(:btc_balance).reduce(&:+)
    @total_market_eth = User.all.pluck(:eth_balance).reduce(&:+)

    @users = User.all
  end
end
