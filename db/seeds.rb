# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)


# first create users
# can't create it though YAML because of the passwords.


Order.all.destroy_all
User.all.destroy_all

fee_user = User.new
fee_user.email = 'fee@user.com'
fee_user.password = 'password'
fee_user.password_confirmation = 'password'
fee_user.save!

4.times do |n|
    user = User.new
    user.email = 'user' + (n+1).to_s + '@user.com'
    user.btc_balance = 3.0
    user.eth_balance = 5.0
    user.eur_balance = 100000.0
    user.password = 'password'
    user.password_confirmation = 'password'
    user.save!
end

# BTC buy orders for user_1
3.times do |n|
    buy_request_order = Order.new
    buy_request_order.price_per_coin = 20000.00 - ((n+1)*1000)
    buy_request_order.coin = 'BTC'
    buy_request_order.coin_amount = 1
    buy_request_order.side= 'buy'
    buy_request_order.user = User.find_by(email: "user1@user.com")
    buy_request_order.save!
end

# BTC sell orders for user_1
3.times do |n|
    sell_request_order = Order.new
    sell_request_order.price_per_coin = 20000.00 + ((n+1)*1000)
    sell_request_order.coin = 'BTC'
    sell_request_order.coin_amount = 1
    sell_request_order.side= 'sell'
    sell_request_order.user = User.find_by(email: "user1@user.com")
    sell_request_order.save!
end


# ETH buy orders for user_1
3.times do |n|
    buy_request_order = Order.new
    buy_request_order.price_per_coin = 1000.00 - ((n+1)*100)
    buy_request_order.coin = 'ETH'
    buy_request_order.coin_amount = 1
    buy_request_order.side= 'buy'
    buy_request_order.user = User.find_by(email: "user1@user.com")
    buy_request_order.save!
end

# ETH sell orders for user_1
3.times do |n|
    sell_request_order = Order.new
    sell_request_order.price_per_coin = 1000.00 + ((n+1)*100)
    sell_request_order.coin = 'ETH'
    sell_request_order.coin_amount = 1
    sell_request_order.side= 'sell'
    sell_request_order.user = User.find_by(email: "user1@user.com")
    sell_request_order.save!
end

    
=begin
# then seed the db if needed
Order.all.destroy_all
seed_file = Rails.root.join('db', 'seed_testing.yml')
if File.file?(seed_file)
    puts("Doing #{seed_file}")
else
    puts("Skipping #{seed_file} as file doesn't exists")
end
config = YAML::load_file(seed_file)
Category.create!(config)
=end