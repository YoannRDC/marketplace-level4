class Order < ApplicationRecord
  belongs_to :user
  enum :side, [:buy, :sell]
end
