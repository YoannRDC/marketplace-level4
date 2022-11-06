require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid test db" do

    fee_user = users(:fee_user)
    assert fee_user.btc_balance == 0, "fee_user btc balance should be 0 at init" 
    assert fee_user.eur_balance == 0, "fee_user eur balance should be 0 at init" 

    user_0 = users(:user_0)
    assert user_0.btc_balance == 3, "user_0 btc balance should be 3 at init" 
    assert user_0.eur_balance == 100000, "user_0 eur balance should be 3 at init" 
  end
end
