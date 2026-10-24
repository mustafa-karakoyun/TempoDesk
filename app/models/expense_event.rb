class ExpenseEvent < ApplicationRecord
  belongs_to :expense

  validates :actor, presence: true
  validates :action, presence: true
end
