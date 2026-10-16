class Ticket < ApplicationRecord
  has_secure_token :access_token
  has_many :comments, dependent: :destroy

  # prefix: true zorunlu: aksi hâlde `new` değeri Ticket.new ile çakışır.
  enum :priority, { low: 0, normal: 1, high: 2, urgent: 3 }, prefix: true
  enum :status, { new: 0, open: 1, solved: 2, closed: 3 }, prefix: true

  validates :title, :description, presence: true
  validates :customer_email, presence: true,
                             format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :priority, :status, presence: true
end
