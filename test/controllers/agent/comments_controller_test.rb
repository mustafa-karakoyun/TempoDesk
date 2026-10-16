require "test_helper"

class Agent::CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.take || User.create!(email_address: "test_agent@tempodesk.example", password: "password123")
    @ticket = Ticket.create!(
      title: "Giriş Sorunu",
      description: "Şifremi kabul etmiyor.",
      customer_email: "musteri@example.com",
      priority: :normal
    )
  end

  test "girissiz kullanici temsilci yaniti ekleyemez" do
    post agent_ticket_comments_path(@ticket), params: {
      comment: { body: "Temsilci yanıtı" }
    }
    assert_redirected_to new_session_path
  end

  test "temsilci yaniti kaydedilir ve new bilet otomatik open olur" do
    sign_in_as @user
    assert @ticket.status_new?

    assert_difference "@ticket.comments.count", 1 do
      post agent_ticket_comments_path(@ticket), params: {
        comment: {
          author_name: "Ayşe Temsilci",
          body: "Talebinizi aldık, kontrolleri yapıyoruz."
        }
      }
    end

    assert_redirected_to agent_ticket_path(@ticket)
    follow_redirect!
    assert_response :success

    comment = @ticket.comments.last
    assert_equal "Ayşe Temsilci", comment.author_name
    assert comment.author_role_agent?
    assert_equal "Talebinizi aldık, kontrolleri yapıyoruz.", comment.body

    # Bilet new -> open oldu mu?
    assert @ticket.reload.status_open?
  end

  test "kapatilmis bilete temsilci yanit ekleyemez" do
    sign_in_as @user
    @ticket.transition_to!("open")
    @ticket.transition_to!("solved")
    @ticket.transition_to!("closed")
    assert @ticket.reload.status_closed?

    assert_no_difference "@ticket.comments.count" do
      post agent_ticket_comments_path(@ticket), params: {
        comment: {
          author_name: "Temsilci",
          body: "Kapalı bilete yanıt denemesi"
        }
      }
    end

    assert_redirected_to agent_ticket_path(@ticket)
    follow_redirect!
    assert_select ".flash-alert", text: /Kapatılmış bir bilete/
  end
end
