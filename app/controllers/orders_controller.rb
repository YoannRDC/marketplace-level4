class OrdersController < ApplicationController
  before_action :set_order, only: %i[ show edit update destroy ]
  before_action :authenticate_user!

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
    orders = Order.all.order('price_per_btc DESC')
    sells = orders.select{|o| o.side == "sell" && o.state == 'created'}
    buys = orders.select{|o| o.side == "buy" && o.state == 'created'}

    # error reporting
    ve = ValidationError.new

    # Order is a Request (buy or sell)   
    if (@order.buy_type == 'request')

      # verify order validity
      ve.add_ve(assert_request_validity(sells, buys))

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
      params.require(:order).permit(:price_per_btc, :btc_amount, :side, :buy_type)
    end

    def assert_request_validity(sells, buys)
      # error reporting
      ve = ValidationError.new
      
      # initiate min sell price and max buy price for order of type request.
      max_btc_price = 999999999.99
      min_btc_price = 0
      if (sells.count != 0 && buys.count != 0) 
        # valeur de l'ordre d'achat max
        request_buy_max_price = sells.last.price_per_btc
        
        # valeur de l'ordre de vente min
        request_sell_min_price = buys.first.price_per_btc

      else 
        if (buys.count == 0) 
          request_buy_max_price = max_btc_price

          # Note: Equality is exclude in test
          request_sell_min_price = sells.last.price_per_btc

        elsif (sells.count == 0) 
          request_buy_max_price = buys.first.price_per_btc

          # Note: Equality is exclude in test
          request_sell_min_price = min_btc_price
        end
      end

      # ****
      # assert order request validity
      # ****

      # TODO: check user total request order is not above it btc balance
      # TODO: check user total request order is not above it eur balance

      # assert user eur balance is enough
      if (@order.side == 'buy')
        eur_to_spend = @order.btc_amount * @order.price_per_btc
        if current_user.eur_balance < eur_to_spend
          error_msg = ": Euros to spend: " + eur_to_spend.to_s + "€, is above your balance: " + current_user.eur_balance.to_s
          ve.add_string(error_msg)
        end
      end

      # assert user BTC balance is enough
      if (@order.side == 'sell')
        if current_user.btc_balance < @order.btc_amount
          error_msg = ": BTC to spend: " + @order.btc_amount.to_s + ", is above your balance: " + current_user.btc_balance.to_s
          ve.add_string(error_msg)
        end
      end

      # assert valid sell request
      if (@order.side == "sell" && @order.price_per_btc <= request_sell_min_price ) 
        error_msg = ": Sell orders must be higher than highest 'buy' order price: " + request_buy_max_price.to_s
        ve.add_string(error_msg)
      end

      # assert valid buy request
      if (@order.side == "buy" && @order.price_per_btc >= request_buy_max_price ) 
        error_msg = ": Buy orders must be lower than lowest 'sell' order price: " + request_sell_min_price.to_s
        ve.add_string(error_msg)
      end

      return ve;
    end

    def execute_buy_market_order(sells) 
      # error reporting
      ve = ValidationError.new
        
      btc_to_buy = @order.btc_amount #init
      cheapest_sell_order = sells.last #cheaper seller

      # while user can buy the full cheapest sell order
      while (sells.count() != 0 && current_user.eur_balance > 0 && btc_to_buy > 0) 

        # *****
        # calculate transaction data 
        # *****

        current_case = "init"

        # user can buy the full cheapest sell order
        if (btc_to_buy >= cheapest_sell_order.btc_amount && current_user.eur_balance >= (cheapest_sell_order.btc_amount * cheapest_sell_order.price_per_btc))
          current_case = "full"
          transaction_btc_amount = cheapest_sell_order.btc_amount
          transaction_cost_in_eur = cheapest_sell_order.btc_amount * cheapest_sell_order.price_per_btc
          
        # user can partially buy the cheapest sell order: Not enough eur.
        elsif (current_user.eur_balance < (cheapest_sell_order.btc_amount * cheapest_sell_order.price_per_btc))
          current_case = "lack_of_money"
          transaction_btc_amount = current_user.eur_balance / cheapest_sell_order.price_per_btc
          transaction_cost_in_eur = transaction_btc_amount * cheapest_sell_order.price_per_btc # =current_user balance

          
        # Last sell order contains more btc than current user need.
        elsif (btc_to_buy < cheapest_sell_order.btc_amount)
          current_case = "partial"
          transaction_btc_amount = btc_to_buy
          transaction_cost_in_eur = btc_to_buy * cheapest_sell_order.price_per_btc

        else 
          error_msg = ": Missing order case."
          ve.add_string(error_msg)
          return ve
        end

        puts "> Transaction"
        puts "  > current_case: " + current_case
        puts "  > transaction_btc_amount: " + transaction_btc_amount.to_s
        puts "  > transaction_cost_in_eur: " + transaction_cost_in_eur.to_s

        # update seller balances
        seller = cheapest_sell_order.user   
        if (seller != current_user)
          seller.btc_balance -= transaction_btc_amount
          seller.eur_balance += transaction_cost_in_eur
          seller.save

          # update buyer balances
          current_user.eur_balance -= transaction_cost_in_eur
          current_user.btc_balance += transaction_btc_amount
          current_user.save
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
          cheapest_sell_order.btc_amount -= transaction_btc_amount
          cheapest_sell_order.save
          
          # create equivalent buy order
          Order.create(price_per_btc: cheapest_sell_order.price_per_btc , btc_amount:transaction_btc_amount, side:'sell', state: 'filled', buy_type: 'request', user:cheapest_sell_order.user)
        end

        # create equivalent buy order
        Order.create(price_per_btc: cheapest_sell_order.price_per_btc , btc_amount:transaction_btc_amount, side:'buy', state: 'filled', buy_type: 'market', user:current_user)

        # prepare next while iteration
        btc_to_buy -= transaction_btc_amount
        cheapest_sell_order = sells.last

      end

      # sells list is empty.
      if (sells.count() == 0)
        error_msg = ": Not enough sell orders to complete your order request."
        ve.add_string(error_msg)
        return ve
      end

      # current_user eur balance is 0.
      if (current_user.eur_balance == 0 && btc_to_buy > 0)
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
      btc_to_sell = @order.btc_amount #init
      higher_buy_order = buys.last #cheaper seller

      # validate btc quantity available
      if (btc_to_sell > current_user.btc_balance)
        error_msg = ": Can't sell more BTC than your balance."
        ve.add_string(error_msg)
        return ve
      end

      # while user can buy the full cheapest sell order
      while (buys.count() != 0 && btc_to_sell > 0) 

        # *****
        # calculate transaction data 
        # *****

        current_case = "init"

        # user has more BTC than the highest buyer order
        if (btc_to_sell >= higher_buy_order.btc_amount)
          current_case = "full"
          transaction_btc_amount = higher_buy_order.btc_amount
          transaction_cost_in_eur = higher_buy_order.btc_amount * higher_buy_order.price_per_btc
          
        # Seller sells less than the full buyer request order
        elsif (btc_to_sell < higher_buy_order.btc_amount)
          current_case = "partial"
          transaction_btc_amount = btc_to_sell
          transaction_cost_in_eur = btc_to_sell * higher_buy_order.price_per_btc

        else 
          error_msg = ": Missing order case."
          ve.add_string(error_msg)
          return ve
        end

        puts "> Transaction"
        puts "  > current_case: " + current_case
        puts "  > transaction_btc_amount: " + transaction_btc_amount.to_s
        puts "  > transaction_cost_in_eur: " + transaction_cost_in_eur.to_s

        # update buyer balances
        buyer = higher_buy_order.user   
        if (buyer != current_user)
          buyer.eur_balance -= transaction_cost_in_eur
          buyer.btc_balance += transaction_btc_amount
          buyer.save

          # update buyer balances
          current_user.btc_balance -= transaction_btc_amount
          current_user.eur_balance += transaction_cost_in_eur
          current_user.save
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
          higher_buy_order.btc_amount -= transaction_btc_amount
          higher_buy_order.save
          
          # create equivalent buy order
          Order.create(price_per_btc: higher_buy_order.price_per_btc , btc_amount:transaction_btc_amount, side:'buy', state: 'filled', buy_type: 'request', user:higher_buy_order.user)
        end

        # create equivalent buy order
        Order.create(price_per_btc: higher_buy_order.price_per_btc , btc_amount:transaction_btc_amount, side:'sell', state: 'filled', buy_type: 'market', user:current_user)

        # prepare next while iteration
        btc_to_sell -= transaction_btc_amount
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

end
