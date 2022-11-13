# README

Original repo: https://github.com/hazardco/rails7-bootstrap5-importmaps.git

# ********
Level 1 completed.
# ********

Devise was installed in imported project.
User management implemented. 
-> User can created an account, sign in and sign out.

Buy and sell orders can be requested.
They appear in the market place. 

# ********
Level 2 completed.
# ********

Instead of matching orders with exact values, orders can be defined with type market.
-> With buy market orders:
    -> The algorithm looks for the cheapeast seller and buy its btc. 
        -> If buy order btc quantity more important than the seller order btc quantiy, the algorithm execute the transaction and repeat with the next cheapest seller.
        -> If buy order btc quantity is less important than the seller order btc quantity, the algorithm calculate what can be bough and execute the transaction.
            -> The algorithm also check the user total balance. (user can't buy more btc than its converted eur_balance)
-> With sell market orders
    -> The algorithm looks for the most expensive buyer btc and sells the btc to him. 
        -> Market order btc quantity cannot be higher than user btc balance. 
        -> If sell order btc quantity is more important than the buyer order btc quantiy, the algorithm execute the transaction and repeat with the next higher buyer.
        -> If buy order btc quantity is lower than the buyer order btc quantity, the algorithm calculate what can be sold and execute the transaction.

A market place stats indicates every user balance (eur and btc), and the total platform balance (eur and btc). 
This can be used to verify that euros and btc are correctly transfered, and that no eur or btc is created or lost during transactions. 

# ********
Level 3 completed.
# ********

The application take a 0.25% fee, debited equaly between the buyer avec the seller. It looks for a user with address fee@user.com and credit its eur_balance.

To seed database:
 -> Stop the server and rails consoles.
 -> rake :drop:_unsafe
 -> rails db:migrate
 -> rails db:seed

To launch the tests:
 -> rails db:migrate RAILS_ENV=test (if needed)
 -> rails test:model
 -> Note: test-system not working. Browser launch but don't open the page. Investigation in progress.

# ********
Level 4 completed.
# ********

Users can buy and sell ETH.
Min unit of BTC is 0.00000001 ETH, same as BTC.