require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ", password: "password")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "varsayilan rol agent olarak atanir" do
    user = User.create!(email_address: "yeni_user@example.com", password: "password")
    assert user.role_agent?
  end

  test "manager ve cfo rolleri gecerlidir" do
    manager = User.create!(email_address: "manager_user@example.com", password: "password", role: :manager)
    assert manager.role_manager?

    cfo = User.create!(email_address: "cfo_user@example.com", password: "password", role: :cfo)
    assert cfo.role_cfo?
  end
end
