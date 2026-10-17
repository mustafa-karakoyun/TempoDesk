require "test_helper"

class CustomerTicketsTest < ActionDispatch::IntegrationTest
  test "ana sayfada (GET /) bilet olusturma formu gorunur" do
    get root_path
    assert_response :success
    assert_select "h1", "Yeni Destek Talebi Oluştur"
    assert_select "form[action='/tickets']"
    assert_select "input[name='ticket[title]']"
    assert_select "input[name='ticket[customer_email]']"
    assert_select "select[name='ticket[priority]']"
    assert_select "textarea[name='ticket[description]']"
  end

  test "gecerli bilgilerle bilet olusturulur ve /t/:access_token sayfasina yonlendirilir" do
    assert_difference "Ticket.count", 1 do
      post tickets_path, params: {
        ticket: {
          title: "Sistem Giriş Hatası",
          customer_email: "musteri@example.com",
          priority: "urgent",
          description: "Giriş yaparken 500 hatası alıyorum."
        }
      }
    end

    ticket = Ticket.last
    assert_redirected_to customer_ticket_path(ticket.access_token)
    follow_redirect!
    assert_response :success
    assert_select "h1.ticket-title", "Sistem Giriş Hatası"
    assert_select ".badge", text: /Acil Öncelik/
    assert_select "#secretLinkInput[value*='#{ticket.access_token}']"
  end

  test "gecersiz bilet bilgisi ile 422 doner ve hatalar gosterilir" do
    assert_no_difference "Ticket.count" do
      post tickets_path, params: {
        ticket: {
          title: "",
          customer_email: "gecersiz-email",
          priority: "normal",
          description: ""
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".form-errors"
  end

  test "gecerli access_token ile bilet sayfasi (GET /t/:access_token) acilir" do
    ticket = Ticket.create!(
      title: "Veri Aktarım Sorunu",
      description: "Veriler eşzamanlanmıyor.",
      customer_email: "ahmet@example.com",
      priority: :high
    )

    get customer_ticket_path(ticket.access_token)
    assert_response :success
    assert_select "h1.ticket-title", "Veri Aktarım Sorunu"
    assert_select ".badge", text: /Yüksek Öncelik/
    assert_select "#ticket-sla-badge"
  end

  test "yanlis access_token durumunda 404 not found doner" do
    get customer_ticket_path("olmayan-token-12345")
    assert_response :not_found
  end

  test "musteri bilet sayfasindan yanit gonderebilir ve yanit akista gorunur" do
    ticket = Ticket.create!(
      title: "Lisans Yenileme",
      description: "Lisans sürem dolmak üzere.",
      customer_email: "selin@example.com",
      priority: :normal
    )

    assert_difference "ticket.comments.count", 1 do
      post customer_ticket_comments_path(ticket.access_token), params: {
        comment: {
          author_name: "Selin Yılmaz",
          body: "Ek olarak fatura bilgilerimi de ekledim."
        }
      }
    end

    assert_redirected_to customer_ticket_path(ticket.access_token)
    follow_redirect!
    assert_response :success
    assert_select ".author-name", text: "Selin Yılmaz"
    assert_select ".badge-customer-role", text: "Müşteri"
    assert_select ".comment-body", text: /Ek olarak fatura bilgilerimi de ekledim/
  end

  test "musteri bos yanit gonderirse 422 doner" do
    ticket = Ticket.create!(
      title: "Lisans Yenileme",
      description: "Lisans sürem dolmak üzere.",
      customer_email: "selin@example.com",
      priority: :normal
    )

    assert_no_difference "ticket.comments.count" do
      post customer_ticket_comments_path(ticket.access_token), params: {
        comment: {
          author_name: "",
          body: ""
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "yanlis token ile yorum gonderilirse 404 doner" do
    post customer_ticket_comments_path("gecersiz-token"), params: {
      comment: {
        author_name: "Ali",
        body: "Bir şeyler yazdım."
      }
    }
    assert_response :not_found
  end

  test "kapatilmis bilete musteri yorum gonderemez ve form gosterilmez" do
    ticket = Ticket.create!(
      title: "Tamamlanan İş",
      description: "Bu bilet çözülecek ve kapatılacak.",
      customer_email: "veli@example.com",
      priority: :normal
    )
    ticket.transition_to!("open")
    ticket.transition_to!("solved")
    ticket.transition_to!("closed")

    get customer_ticket_path(ticket.access_token)
    assert_response :success
    assert_select ".ticket-closed-banner"
    assert_select "form[action='#{customer_ticket_comments_path(ticket.access_token)}']", count: 0

    assert_no_difference "ticket.comments.count" do
      post customer_ticket_comments_path(ticket.access_token), params: {
        comment: {
          author_name: "Veli",
          body: "Yeniden yazmayı deniyorum."
        }
      }
    end

    assert_redirected_to customer_ticket_path(ticket.access_token)
    follow_redirect!
    assert_select ".flash-alert", text: /Kapatılmış bir bilete yeni yanıt eklenemez/
  end

  test "cozulmus ve cozum ozeti olan bilette musteri cozum ozeti kutusunu gorur" do
    ticket = Ticket.create!(
      title: "Alan Adı Yönlendirme",
      description: "DNS ayarları çalışmıyor.",
      customer_email: "ahmet@example.com",
      priority: :normal
    )
    ticket.transition_to!("open")
    ozet_metni = "CNAME kaydı doğru sunucu IP'sine yönlendirildi ve TTL süresi güncellendi."
    ticket.transition_to!("solved", resolution_summary: ozet_metni)

    get customer_ticket_path(ticket.access_token)
    assert_response :success
    assert_select ".resolution-summary-box"
    assert_select ".resolution-title", "Çözüm Özeti"
    assert_select ".resolution-summary-text", text: /#{ozet_metni}/
  end
end
