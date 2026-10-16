require "test_helper"

class Agent::TicketsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.take || User.create!(email_address: "test_agent@tempodesk.example", password: "password123")
    @ticket = Ticket.create!(
      title: "Sunucu Yanıt Vermiyor",
      description: "Ana sunucuda kesinti yaşanıyor.",
      customer_email: "musteri@example.com",
      priority: :urgent
    )
  end

  test "girissiz kullanici /agent/tickets acamaz, girise yonlendirilir" do
    get agent_tickets_path
    assert_redirected_to new_session_path
  end

  test "girisli temsilci /agent/tickets acabilir ve bilet listesini gorur" do
    sign_in_as @user
    get agent_tickets_path
    assert_response :success
    assert_select "h1.dashboard-title", "Destek Masası — Bilet Sırası"
    assert_select "td", text: /Sunucu Yanıt Vermiyor/
    assert_select "#agentTicketsTable"
  end

  test "bilet listesi SLA onceligine gore siralanir" do
    urgent_ticket = Ticket.create!(
      title: "Acil Sistem Kesintisi",
      description: "Detaylar",
      customer_email: "acil@example.com",
      priority: :urgent
    )
    low_ticket = Ticket.create!(
      title: "Dusuk Oncelikli Soru",
      description: "Detaylar",
      customer_email: "dusuk@example.com",
      priority: :low
    )

    sign_in_as @user
    get agent_tickets_path
    assert_response :success
    assert_select "#agentTicketsTable"
    # Acil olan daha kisa sureli (due_at daha erken) oldugu icin once listelenir
    assert response.body.index("Acil Sistem Kesintisi") < response.body.index("Dusuk Oncelikli Soru")
  end

  test "girissiz kullanici bilet detayini acamaz" do
    get agent_ticket_path(@ticket)
    assert_redirected_to new_session_path
  end

  test "girisli temsilci bilet detayini acar ve durum butonlarini gorur" do
    sign_in_as @user
    get agent_ticket_path(@ticket)
    assert_response :success
    assert_select "h1.ticket-title", text: /Sunucu Yanıt Vermiyor/
    assert_select "form[action='#{transition_agent_ticket_path(@ticket, status: 'open')}']"
  end

  test "izinli durum gecisleri calisir: new -> open -> solved -> closed" do
    sign_in_as @user

    # new -> open
    patch transition_agent_ticket_path(@ticket), params: { status: "open" }
    assert_redirected_to agent_ticket_path(@ticket)
    assert @ticket.reload.status_open?
    assert_nil @ticket.solved_at

    # open -> solved
    patch transition_agent_ticket_path(@ticket), params: { status: "solved" }
    assert_redirected_to agent_ticket_path(@ticket)
    assert @ticket.reload.status_solved?
    assert @ticket.solved_at.present?

    # solved -> closed
    patch transition_agent_ticket_path(@ticket), params: { status: "closed" }
    assert_redirected_to agent_ticket_path(@ticket)
    assert @ticket.reload.status_closed?
  end

  test "solved -> open yeniden acma calisir ve solved_at temizlenir" do
    sign_in_as @user
    @ticket.transition_to!("open")
    @ticket.transition_to!("solved")
    assert @ticket.reload.solved_at.present?

    patch transition_agent_ticket_path(@ticket), params: { status: "open" }
    assert_redirected_to agent_ticket_path(@ticket)
    assert @ticket.reload.status_open?
    assert_nil @ticket.solved_at
  end

  test "gecersiz gecis denemesi sunucuyu cokertmez, anlasilir bir hata mesajiyla yonlendirir" do
    sign_in_as @user
    # @ticket 'new' durumundadir, dogrudan 'closed' yapilamaz!
    assert @ticket.status_new?

    patch transition_agent_ticket_path(@ticket), params: { status: "closed" }
    assert_redirected_to agent_ticket_path(@ticket)
    follow_redirect!
    assert_select ".flash-alert", text: /Geçersiz durum geçişi/
    assert @ticket.reload.status_new?
  end
end
