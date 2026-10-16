class Comment < ApplicationRecord
  belongs_to :ticket

  enum :author_role, { customer: 0, agent: 1 }, prefix: true

  validates :author_role, :author_name, :body, presence: true
end
