class Order < ApplicationRecord
  belongs_to :user
  enum :side, [:buy, :sell]
  enum :state, [:created, :filled]
  enum :buy_type, [:request, :market]
end
