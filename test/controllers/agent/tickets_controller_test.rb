require "test_helper"

class Agent::TicketsControllerTest < ActionDispatch::IntegrationTest
  test "girissiz kullanici /agent/tickets acamaz, girise yonlendirilir" do
    get agent_tickets_path
    assert_redirected_to new_session_path
  end

  test "girisli temsilci /agent/tickets acabilir" do
    sign_in_as User.take
    get agent_tickets_path
    assert_response :success
  end
end
