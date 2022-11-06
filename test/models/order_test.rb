require "test_helper"

class OrderTest < ActiveSupport::TestCase
   test "initial test orders" do

    # buy orders
    buy_order_0 = orders(:buy_order_0)
    puts "buy_order_0: " + buy_order_0.to_s
    assert buy_order_0.price_per_btc == 19000, "order_0 price per btc should be 19000."
    assert buy_order_0.btc_amount == 1, "buy_order_0.btc_amount should be 1"
    assert buy_order_0.side == 'buy', "order_0 side should be buy"
    
    buy_order_1 = orders(:buy_order_1)
    assert buy_order_1.price_per_btc == 18000, "buy_order_1 per btc should be 18000."

    # sell orders
    sell_order_1 = orders(:sell_order_1)
    assert sell_order_1.price_per_btc == 22000, "sell_order_1 per btc should be 22000."
   end

   test "buy order" do

    # user_1 placed the request orders. See MarketPlaceV2\test\fixtures\orders.yml
    # user_2 is the market buy and seller

    # prepare data
    user2 = User.find_by(email: "user2@user.com")

=begin
    #buy market order
    buy_market_order = Order.new
    buy_market_order.side = 'buy'
    buy_market_order.buy_type = 'market'
    buy_market_order.price_per_btc = '1' #useless
    buy_market_order.btc_amount = 1.5
    buy_market_order.user = user2
    buy_market_order.save

    puts "user2.eur_balance: " + user2.eur_balance.to_s
    assert user2.eur_balance == 68000, "user2 blanace should be 100000 - (21000 + 22000/2) = 68000"
=end
   end
  
end
