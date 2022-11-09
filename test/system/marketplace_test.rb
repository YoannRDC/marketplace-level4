require "application_system_test_case"

class MarketplaceTest < ApplicationSystemTestCase

  setup do
    puts " New Start YR"
    # current_user = users(:user_2)
    # @order = orders(:buy_order_0)
  end

  test "visiting the index" do
    session = Capybara::Session.new(:selenium_chrome)
    session.visit '/'
    assert_selector "h1", text: "Market place"
=begin
    session.click_on 'Hello World' # interact with the page, to get Chrome to fire `beforeunload`
    session.driver.browser.switch_to.alert.accept
    session.visit '/'


    puts "visiting the index"
    
    visit('/users/sign_in')
    puts "visiting the index YR 1"
    assert_selector "h2", text: "Log in"
    puts "visiting the index YR 2"
=end
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
