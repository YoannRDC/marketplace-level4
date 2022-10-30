class OrdersController < ApplicationController
  before_action :set_order, only: %i[ show edit update destroy ]
  before_action :authenticate_user!

  # GET /orders or /orders.json
  def index
    @orders = Order.select{|o| o.user == current_user}
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
  def create
    @order = Order.new(order_params)

    @orders = Order.all.order('price_per_btc DESC')
    @sells = @orders.select{|o| o.side == "sell"}
    @buys = @orders.select{|o| o.side == "buy"}

    if (@order.side == "sell" && @order.price_per_btc < @buys.first.price_per_btc) 
      error_msg = ": Sell orders must be higher than highest 'buy' order price: " + @buys.first.price_per_btc.to_s
      @order.errors.add(:invalid_order_range, error_msg)
      flash[:notice] = @order.errors.full_messages
      redirect_to root_path(@order)
      return
    end

    @order.user = current_user

    respond_to do |format|
      if @order.save
        format.html { redirect_to order_url(@order), notice: "Order was successfully created." }
        format.json { render :show, status: :created, location: @order }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
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

  # returns the average price between the closest buy and sell orders.
  def get_average_price
    @orders = Order.all.order('price_per_btc DESC')

    @sells = @orders.select{|o| o.side == "sell"}
    @buys = @orders.select{|o| o.side == "buy"}

    return (@sells.last.price_per_btc + @buys.first.price_per_btc)/2
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def order_params
      params.require(:order).permit(:price_per_btc, :btc_amount, :side)
    end
end
