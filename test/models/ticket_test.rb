require "test_helper"

class TicketTest < ActiveSupport::TestCase
  def build_ticket(**overrides)
    Ticket.create!({ title: "Giriş yapamıyorum", description: "Şifrem çalışmıyor",
                     customer_email: "musteri@example.com", priority: :normal }.merge(overrides))
  end

  def move_to(ticket, *statuses)
    statuses.each { |s| ticket.transition_to!(s) }
    ticket
  end

  # --- Oluşturma ve due_at ---

  test "yeni bilet new durumunda ve normal oncelikle baslar, token uretilir" do
    ticket = build_ticket
    assert ticket.status_new?
    assert ticket.priority_normal?
    assert ticket.access_token.present?
  end

  test "due_at olusturmada SlaPolicy ile otomatik atanir" do
    travel_to Time.zone.local(2026, 10, 16, 12, 0, 0) do
      ticket = build_ticket(priority: :urgent)
      assert_equal SlaPolicy.due_at(priority: :urgent, from: Time.current), ticket.due_at
    end
  end

  test "acikca verilen due_at ezilmez" do
    verilen = Time.zone.local(2026, 10, 14, 12, 0, 0)
    assert_equal verilen, build_ticket(due_at: verilen).due_at
  end

  test "gecersiz e-posta ve bos alanlar reddedilir" do
    ticket = Ticket.new(title: "", description: "", customer_email: "gecersiz")
    assert_not ticket.valid?
    assert ticket.errors[:title].any?
    assert ticket.errors[:description].any?
    assert ticket.errors[:customer_email].any?
  end

  # --- Durum geçişleri ---

  test "izinli gecisler calisir: new->open, open->solved, solved->closed" do
    ticket = build_ticket
    ticket.transition_to!("open")
    assert ticket.status_open?
    ticket.transition_to!("solved")
    assert ticket.status_solved?
    ticket.transition_to!("closed")
    assert ticket.status_closed?
  end

  test "solved->open yeniden acma calisir" do
    ticket = move_to(build_ticket, "open", "solved")
    ticket.transition_to!("open")
    assert ticket.status_open?
  end

  test "izinsiz gecisler InvalidTransition firlatir" do
    assert_raises(Ticket::InvalidTransition) { build_ticket.transition_to!("closed") }
    assert_raises(Ticket::InvalidTransition) { build_ticket.transition_to!("solved") }
    assert_raises(Ticket::InvalidTransition) { move_to(build_ticket, "open").transition_to!("closed") }
    assert_raises(Ticket::InvalidTransition) { move_to(build_ticket, "open", "solved", "closed").transition_to!("open") }
  end

  test "bilinmeyen durum ve ayni duruma gecis InvalidTransition firlatir, durum degismez" do
    ticket = build_ticket
    assert_raises(Ticket::InvalidTransition) { ticket.transition_to!("bilinmeyen") }
    assert_raises(Ticket::InvalidTransition) { ticket.transition_to!("new") }
    assert ticket.reload.status_new?
  end

  test "solved gecisi solved_at yazar, yeniden acma temizler" do
    ticket = move_to(build_ticket, "open")
    assert_nil ticket.solved_at

    travel_to Time.zone.local(2026, 10, 16, 15, 0, 0) do
      ticket.transition_to!("solved")
      assert_equal Time.current, ticket.solved_at
    end

    ticket.transition_to!("open")
    assert_nil ticket.reload.solved_at
  end

  # --- Yorumlar ---

  test "ilk temsilci yanitinda new bilet otomatik open olur" do
    ticket = build_ticket
    ticket.comments.create!(author_role: :agent, author_name: "Temsilci", body: "Bakıyoruz")
    assert ticket.reload.status_open?
  end

  test "musteri yorumu new bileti open yapmaz" do
    ticket = build_ticket
    ticket.comments.create!(author_role: :customer, author_name: "Müşteri", body: "Acil")
    assert ticket.reload.status_new?
  end

  test "temsilci yaniti solved bileti yeniden acmaz" do
    ticket = move_to(build_ticket, "open", "solved")
    ticket.comments.create!(author_role: :agent, author_name: "Temsilci", body: "Çözüldü")
    assert ticket.reload.status_solved?
  end

  test "closed bilete yorum eklenemez" do
    ticket = move_to(build_ticket, "open", "solved", "closed")
    comment = ticket.comments.build(author_role: :customer, author_name: "Müşteri", body: "Merhaba")

    assert_not comment.save
    assert comment.errors[:base].any?
    assert_raises(ActiveRecord::RecordInvalid) do
      ticket.comments.create!(author_role: :agent, author_name: "Temsilci", body: "Merhaba")
    end
    assert_equal 0, ticket.comments.count
  end

  # --- SLA (zaman makinesi yalnızca testlerde) ---

  test "travel_to: urgent bilet 3 sa 59 dk sonra ihlalsiz, 4 sa 1 dk sonra ihlalli" do
    baslangic = Time.zone.local(2026, 10, 16, 12, 0, 0)
    ticket = nil
    travel_to(baslangic) { ticket = build_ticket(priority: :urgent) }

    travel_to(baslangic + 3.hours + 59.minutes) { assert_not ticket.sla_breached? }
    travel_to(baslangic + 4.hours + 1.minute)   { assert ticket.sla_breached? }
  end

  test "tam due_at aninda henuz ihlal degildir" do
    baslangic = Time.zone.local(2026, 10, 16, 12, 0, 0)
    ticket = nil
    travel_to(baslangic) { ticket = build_ticket(priority: :urgent) }

    travel_to(ticket.due_at) { assert_not ticket.sla_breached? }
  end

  test "gec cozulen bilet ihlalli kalir, zamaninda cozulen ihlalsiz kalir" do
    baslangic = Time.zone.local(2026, 10, 16, 12, 0, 0)
    gec = zamaninda = nil
    travel_to(baslangic) do
      gec = move_to(build_ticket(priority: :urgent), "open")
      zamaninda = move_to(build_ticket(priority: :urgent), "open")
    end

    travel_to(baslangic + 3.hours) { zamaninda.transition_to!("solved") }
    travel_to(baslangic + 5.hours) { gec.transition_to!("solved") }

    # Çözüldükten çok sonra bile sonuç değişmez: çözüm anına bakılır.
    travel_to(baslangic + 30.days) do
      assert_not zamaninda.reload.sla_breached?
      assert gec.reload.sla_breached?
    end
  end

  test "ihlal veritabaninda saklanmaz" do
    assert_not_includes Ticket.column_names, "sla_breached"
  end
end
