require "application_system_test_case"

class OrdersTest < ApplicationSystemTestCase
  driven_by :selenium, using: :chrome

  setup do
    puts "@Start YR"
    # current_user = users(:user_2)
    @order = orders(:buy_order_0)
    puts "@order YR"
  end

  test "visiting the index" do
    puts "controller test done"
    visit orders_url
    assert_selector "h1", text: "Your orders"
    puts "visiting the index YR"
  end
=begin
  test "should create order" do
    visit orders_url
    click_on "New order"

    click_on "Create Order"

    assert_text "Order was successfully created"
    click_on "Back"
  end

  test "should update Order" do
    visit order_url(@order)
    click_on "Edit this order", match: :first

    click_on "Update Order"

    assert_text "Order was successfully updated"
    click_on "Back"
  end

  test "should destroy Order" do
    visit order_url(@order)
    click_on "Destroy this order", match: :first

    assert_text "Order was successfully destroyed"
  end
=end
end
