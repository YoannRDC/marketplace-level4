require 'singleton'
require 'Service'

class OrdersController < ApplicationController
  before_action :set_order, only: %i[ show edit update destroy ]
  before_action :authenticate_user!

  # Market place fees
  FEES = 0.0025

  # GET /orders or /orders.json
  def index
    @orders_request = Order.select{|o| o.user == current_user && o.state != 'filled'}
    @orders_filled = Order.select{|o| o.user == current_user && o.state == 'filled'}
  end

  # GET /orders/1 or /orders/1.json
  def show
  end

  # GET /orders/new
  def new
    @order = Order.new
  end

  # GET /orders/1/edit
  def edit
  end

  # POST /orders or /orders.json
  def create()
    @order = Order.new(order_params)
    @order.user = current_user

    # prepare data
    orders = Order.all.order('coin ASC, price_per_coin DESC')

    #coin type
    if (@order.coin == 'BTC')
      user_coin_balance = current_user.btc_balance
      sells = orders.select{|o| o.side == "sell" && o.state == 'created' && o.coin == 'BTC'}
      buys = orders.select{|o| o.side == "buy" && o.state == 'created' && o.coin == 'BTC'}
    elsif (@order.coin == 'ETH')
      user_coin_balance = current_user.eth_balance
      sells = orders.select{|o| o.side == "sell" && o.state == 'created' && o.coin == 'ETH'}
      buys = orders.select{|o| o.side == "buy" && o.state == 'created' && o.coin == 'ETH'}
    end

    # error reporting
    ve = ValidationError.new

    # Order is a Request (buy or sell)   
    if (@order.buy_type == 'request')

      # verify order validity
      ve.add_ve(assert_request_validity(sells, buys, user_coin_balance))

      # request order is not valid
      if ve.contains_errors
        @order.errors.add(:invalid_order, ve.get_errors.to_s)
        flash[:alert] = @order.errors.full_messages
        redirect_to root_path(@order)
        return
      end

      # request order is valid
      if @order.save
        flash[:notice] = "Request order placed successfully"
        redirect_to root_path(@order)
        return
      # error saving order.
      else
        error_msg = ": Error saving the order of type request."
        @order.errors.add(:invalid_order, error_msg)
        flash[:alert] = @order.errors.full_messages
        redirect_to root_path(@order)
        return
      end
    end

    
    # verify order validity
    ve.add_ve(assert_market_order_validity(user_coin_balance))

    # market order is not valid
    if ve.contains_errors
      @order.errors.add(:invalid_order, ve.get_errors.to_s)
      flash[:alert] = @order.errors.full_messages
      redirect_to root_path(@order)
      return
    end 

    # Order is a Market buy
    if (@order.buy_type == 'market' && @order.side == 'buy')
      ve.add_ve(execute_buy_market_order(sells))

    # Order is a Market sell
    elsif (@order.buy_type == 'market' && @order.side == 'sell')
      ve.add_ve(execute_sell_market_order(buys))
    end

    # market order is not fully filled
    if ve.contains_errors
      @order.errors.add(:invalid_order, ve.get_errors.to_s)
      flash[:alert] = @order.errors.full_messages
      redirect_to root_path(@order)
      return
    end
    
    # return success market order
    flash[:success] = @order.errors.full_messages
    redirect_to root_path(@order)
  end

  # PATCH/PUT /orders/1 or /orders/1.json
  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to order_url(@order), notice: "Order was successfully updated." }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1 or /orders/1.json
  def destroy
    @order.destroy

    respond_to do |format|
      format.html { redirect_to orders_url, notice: "Order was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def order_params
      params.require(:order).permit(:price_per_coin, :coin_amount, :side, :buy_type, :coin)
    end

    def assert_market_order_validity(user_coin_balance)
      # error reporting
      ve = ValidationError.new

      # validate coin quantity available
      if (@order.coin_amount > user_coin_balance)
        error_msg = ": Can't sell more coin than your balance."
        ve.add_string(error_msg)
        return ve
      end
      return ve;
    end

    def assert_request_validity(sells, buys, user_coin_balance)
      # error reporting
      ve = ValidationError.new
      
      # initiate min sell price and max buy price for order of type request.
      max_coin_price = 999999999.99
      min_coin_price = 0
      if (sells.count != 0 && buys.count != 0) 
        # valeur de l'ordre d'achat max
        request_buy_max_price = sells.last.price_per_coin
        
        # valeur de l'ordre de vente min
        request_sell_min_price = buys.first.price_per_coin

      else 
        if (buys.count == 0) 
          request_buy_max_price = max_coin_price

          # Note: Equality is exclude in test
          request_sell_min_price = sells.last.price_per_coin

        elsif (sells.count == 0) 
          request_buy_max_price = buys.first.price_per_coin

          # Note: Equality is exclude in test
          request_sell_min_price = min_coin_price
        end
      end

      # ****
      # assert order request validity
      # ****

      # assert user eur balance is enough
      if (@order.side == 'buy')
        # euros for this order
        eur_to_spend = @order.coin_amount * @order.price_per_coin

        # Sum of euros for previous orders.
        buy_orders_eur_sum = eur_to_spend
        created_user_orders = Order.where(user:current_user, side:'buy', state:'created', buy_type: 'request')
        created_user_orders.each do |order|
          buy_orders_eur_sum += (order.coin_amount * order.price_per_coin)
        end

        if current_user.eur_balance < buy_orders_eur_sum
          error_msg = ": Your total request order balance would exceed your euros balance. Orders sum:" + buy_orders_eur_sum + "€. ".
          ve.add_string(error_msg)
        end
      end

      # assert user coin balance is enough to sell taht many coin
      if (@order.side == 'sell')

        # coin for this order
        sell_orders_coin_sum = @order.coin_amount

        # Sum of coin for previous orders.
        created_user_orders = Order.where(user:current_user, side:'sell', state:'created', buy_type: 'request')
        created_user_orders.each do |order|
          sell_orders_coin_sum += order.coin_amount
        end
        logger.debug "@sell_orders_coin_sum: #{sell_orders_coin_sum}"

        if user_coin_balance < sell_orders_coin_sum
          error_msg = ": Your total request order balance would exceed your balance. Orders sum:" + sell_orders_coin_sum.to_s
          ve.add_string(error_msg)
        end
      end

      # assert valid sell request
      if (@order.side == "sell" && @order.buy_type == "request" && @order.price_per_coin <= request_sell_min_price ) 
        error_msg = ": Sell orders must be higher than highest 'buy' order price: " + request_buy_max_price.to_s
        ve.add_string(error_msg)
      end

      # assert valid buy request
      if (@order.side == "buy" && @order.buy_type == "request" && @order.price_per_coin >= request_buy_max_price ) 
        error_msg = ": Buy orders must be lower than lowest 'sell' order price: " + request_sell_min_price.to_s
        ve.add_string(error_msg)
      end

      return ve;
    end

    def execute_buy_market_order(sells) 
      # error reporting
      ve = ValidationError.new
        
      coin_to_buy = @order.coin_amount #init
      cheapest_sell_order = sells.last #cheaper seller

      # while user can buy the full cheapest sell order
      while (sells.count() != 0 && current_user.eur_balance > 0 && coin_to_buy > 0) 
        # *****
        # calculate transaction data 
        # *****

        current_case = "init"

        cheapest_sell_order_cost = (cheapest_sell_order.coin_amount * cheapest_sell_order.price_per_coin)
        puts "FEES"
        puts "  > cheapest_sell_order_cost: " + cheapest_sell_order_cost.to_s
        fees_for_cheapest_sell_order_cost = Service.instance.round_eur(cheapest_sell_order_cost * FEES)
        puts "  > FULL fees: " + fees_for_cheapest_sell_order_cost.to_s
        cheapest_sell_order_cost_with_fees = cheapest_sell_order_cost + fees_for_cheapest_sell_order_cost
        
        # user can partially buy the cheapest sell order: Not enough eur.
        if (current_user.eur_balance < cheapest_sell_order_cost_with_fees )
          current_case = "lack_of_money"
          transaction_price_per_coin_with_fees = (cheapest_sell_order.price_per_coin * (1 + FEES))
          transaction_coin_amount = current_user.eur_balance / transaction_price_per_coin_with_fees
          transaction_cost_in_eur_without_fees = transaction_coin_amount * cheapest_sell_order.price_per_coin # =current_user balance
          
        # Last sell order contains more coin than current user need.
        elsif (coin_to_buy < cheapest_sell_order.coin_amount)
          current_case = "partial"
          transaction_coin_amount = coin_to_buy
          transaction_cost_in_eur_without_fees = coin_to_buy * cheapest_sell_order.price_per_coin


        # user can buy the full cheapest sell order
        else 
          current_case = "full"
          transaction_coin_amount = cheapest_sell_order.coin_amount
          transaction_cost_in_eur_without_fees = cheapest_sell_order.coin_amount * cheapest_sell_order.price_per_coin

        end

        # calculate fees
        transaction_fees = transaction_cost_in_eur_without_fees * FEES

        puts "> Transaction"
        puts "  > current_case: " + current_case
        puts "  > transaction_coin_amount: " + transaction_coin_amount.to_s
        puts "  > transaction_cost_in_eur: " + transaction_cost_in_eur_without_fees.to_s
        puts "  > transaction_fees: " + transaction_fees.to_s

        # update seller balances
        seller = cheapest_sell_order.user   
        if (seller != current_user)
          
          eur_credited_user = seller
          coin_credited_user = current_user
          update_users_balance(eur_credited_user, coin_credited_user, transaction_cost_in_eur_without_fees, transaction_coin_amount, transaction_fees)
        end

        # ******
        # update sell order
        # ******
        
        # full order
        if (current_case == "full")
          # update seller order
          cheapest_sell_order.state = 'filled'
          cheapest_sell_order.save

          # remove it from the sell list for next iteration     
          sells.delete(cheapest_sell_order)

          # partial order => update cheapest_sell_order and create a filled order 
        else 

          # update cheapest_sell_order 
          cheapest_sell_order.coin_amount -= transaction_coin_amount
          cheapest_sell_order.save
          
          # create equivalent buy order
          Order.create(price_per_coin: cheapest_sell_order.price_per_coin , coin_amount:transaction_coin_amount, side:'sell', state: 'filled', buy_type: 'request',  coin: @order.coin, user:cheapest_sell_order.user)
        end

        # create equivalent buy order
        Order.create(price_per_coin: cheapest_sell_order.price_per_coin , coin_amount:transaction_coin_amount, side:'buy', state: 'filled', buy_type: 'market', coin: @order.coin, user:current_user)

        # prepare next while iteration
        coin_to_buy -= transaction_coin_amount
        cheapest_sell_order = sells.last

      end

      # sells list is empty.
      if (sells.count() == 0)
        error_msg = ": Not enough sell orders to complete your order request."
        ve.add_string(error_msg)
        return ve
      end

      # current_user eur balance is 0.
      if (current_user.eur_balance == 0 && coin_to_buy > 0)
        error_msg = ": Not enough euro to complet the market request."
        ve.add_string(error_msg)
        return ve
      end
      return ve
    end

    def execute_sell_market_order(buys) 
      # error reporting
      ve = ValidationError.new
        
      # prepare data
      coin_to_sell = @order.coin_amount #init
      higher_buy_order = buys.last #cheaper seller

      # while user can buy the full cheapest sell order
      while (buys.count() != 0 && coin_to_sell > 0) 
        # *****
        # calculate transaction data 
        # *****

        current_case = "init"

        # user has more coin than the highest buyer order
        if (coin_to_sell >= higher_buy_order.coin_amount)
          current_case = "full"
          transaction_coin_amount = higher_buy_order.coin_amount
          transaction_cost_in_eur_without_fees = higher_buy_order.coin_amount * higher_buy_order.price_per_coin
          
        # Seller sells less than the full buyer request order
        elsif (coin_to_sell < higher_buy_order.coin_amount)
          current_case = "partial"
          transaction_coin_amount = coin_to_sell
          transaction_cost_in_eur_without_fees = coin_to_sell * higher_buy_order.price_per_coin

        else 
          error_msg = ": Missing order case."
          ve.add_string(error_msg)
          return ve
        end
        
        transaction_fees_eur = transaction_cost_in_eur_without_fees * 0.0025

        puts "> Transaction"
        puts "  > current_case: " + current_case
        puts "  > transaction_coin_amount: " + transaction_coin_amount.to_s
        puts "  > transaction_cost_in_eur: " + transaction_cost_in_eur_without_fees.to_s
        puts "  > transaction_fees: " + transaction_fees_eur.to_s

        buyer = higher_buy_order.user   

        # we don't take fees if user buy coin to himself.
        if (buyer != current_user)
          eur_credited_user = current_user
          coin_credited_user = buyer
          update_users_balance(eur_credited_user, coin_credited_user, transaction_cost_in_eur_without_fees, transaction_coin_amount, transaction_fees_eur)
        end

        # ******
        # update sell order
        # ******
        
        # full order
        if (current_case == "full")
          # update seller order
          higher_buy_order.state = 'filled'
          higher_buy_order.save

          # remove it from the sell list for next iteration     
          buys.delete(higher_buy_order)

          # partial order => update cheapest_sell_order and create a filled order 
        else 

          # update cheapest_sell_order 
          higher_buy_order.coin_amount -= transaction_coin_amount
          higher_buy_order.save
          
          # create equivalent buy order
          Order.create(price_per_coin: higher_buy_order.price_per_coin , coin_amount:transaction_coin_amount, side:'buy', state: 'filled', buy_type: 'request', user:higher_buy_order.user)
        end

        # create equivalent buy order
        Order.create(price_per_coin: higher_buy_order.price_per_coin , coin_amount:transaction_coin_amount, side:'sell', state: 'filled', buy_type: 'market', user:current_user)

        # prepare next while iteration
        coin_to_sell -= transaction_coin_amount
        higher_buy_order = buys.last

      end

      # sells list is empty.
      if (buys.count() == 0)
        error_msg = ": Not enough buy orders to complete your sell market query."
        ve.add_string(error_msg)
        return ve
      end
      return ve
    end

    def update_users_balance(eur_credited_user, coin_credited_user, transaction_cost_in_eur_without_fees, transaction_coin_amount, transaction_fees_eur)

      # update market place balance
      fee_user = User.find_by(email: "fee@user.com")
      if (!fee_user.nil?)
        fee_user.eur_balance += transaction_fees_eur
        fee_user.save
      else 
        transaction_fees_eur = 0
      end

      # update buyer balance
      coin_credited_user.eur_balance -= (transaction_cost_in_eur_without_fees + transaction_fees_eur/2)
      if (@order.coin == 'BTC')
        coin_credited_user.btc_balance += transaction_coin_amount
      elsif (@order.coin == 'ETH')
        coin_credited_user.eth_balance += transaction_coin_amount
      end
      coin_credited_user.save

      # update seller balance
      if (@order.coin == 'BTC')
        eur_credited_user.btc_balance -= transaction_coin_amount
      elsif (@order.coin == 'ETH')
        eur_credited_user.eth_balance -= transaction_coin_amount
      end
      eur_credited_user.eur_balance += (transaction_cost_in_eur_without_fees - transaction_fees_eur/2)
      eur_credited_user.save
    end
end
