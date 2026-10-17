require "test_helper"

class TicketsHelperTest < ActionView::TestCase
  BASLANGIC = Time.zone.local(2026, 10, 16, 12, 0, 0)

  def urgent_ticket
    travel_to(BASLANGIC) do
      Ticket.create!(title: "T", description: "D", customer_email: "m@example.com", priority: :urgent)
    end
  end

  test "acik bilet icin kalan sure saat ve dakika olarak gosterilir" do
    ticket = urgent_ticket
    travel_to(BASLANGIC + 1.minute) { assert_equal "3 sa 59 dk kaldı", sla_label(ticket) }
    travel_to(BASLANGIC)            { assert_equal "4 sa 0 dk kaldı",  sla_label(ticket) }
  end

  test "bir saatten az kalinca yalnizca dakika gosterilir" do
    ticket = urgent_ticket
    travel_to(ticket.due_at - 45.minutes) { assert_equal "45 dk kaldı", sla_label(ticket) }
  end

  test "son dakikada 1 dk'dan az kaldi yazar" do
    ticket = urgent_ticket
    travel_to(ticket.due_at - 30.seconds) { assert_equal "1 dk'dan az kaldı", sla_label(ticket) }
  end

  # Metin sözleşmesi değişti (görsel iyileştirme turu):
  #  - Açık ve ihlalli bilet artık düz "SLA aşıldı" yerine aşım süresini yazar ("5 sa 12 dk aşıldı").
  #  - Çözülmüş ama geç çözülen bilet artık "SLA aşıldı" DEĞİL, sönük "Geç çözüldü" etiketini alır;
  #    çünkü bilet kapanmıştır ve ajanın harekete geçeceği açık bir ihlal yoktur.
  # İhlalin kendisi (Ticket#sla_breached?) değişmedi, yalnızca helper'ın ürettiği metin değişti.
  test "acik ve ihlalli bilet asim suresini yazar" do
    ticket = urgent_ticket
    travel_to(ticket.due_at + 30.seconds) do
      assert_equal "1 dk'dan az aşıldı", sla_label(ticket)
      assert_equal "badge-breached", sla_badge_class(ticket)
    end
    travel_to(BASLANGIC + 4.hours + 1.minute) { assert_equal "1 dk aşıldı", sla_label(ticket) }
    travel_to(BASLANGIC + 4.hours + 5.hours + 12.minutes) { assert_equal "5 sa 12 dk aşıldı", sla_label(ticket) }
    travel_to(BASLANGIC + 1.hour) { assert_equal "badge-active", sla_badge_class(ticket) }
  end

  test "zamaninda cozulen bilet SLA icinde cozuldu yazar, gec cozulen Gec cozuldu yazar" do
    zamaninda = urgent_ticket
    gec = urgent_ticket
    [ zamaninda, gec ].each { |t| travel_to(BASLANGIC) { t.transition_to!("open") } }

    travel_to(BASLANGIC + 2.hours) { zamaninda.transition_to!("solved") }
    travel_to(BASLANGIC + 6.hours) { gec.transition_to!("solved") }

    travel_to(BASLANGIC + 10.hours) do
      assert_equal "SLA içinde çözüldü", sla_label(zamaninda)
      assert_equal "badge-resolved", sla_badge_class(zamaninda)

      assert_equal "Geç çözüldü", sla_label(gec)
      assert_no_match(/SLA aşıldı/, sla_label(gec))
      assert_equal "badge-late", sla_badge_class(gec)
    end
  end
end
