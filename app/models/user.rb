class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  enum :role, { agent: 0, manager: 1, cfo: 2 }, prefix: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
