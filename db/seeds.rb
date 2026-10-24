# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# ------------------------------------------------------------------------------
# 1. Demo Kullanıcı Hesapları (Kâhya)
# ------------------------------------------------------------------------------
# Şifreler ENV'den gelir (production'da zorunlu, yerelde güvenli varsayılan).
agent_password = Rails.env.production? ? ENV.fetch("AGENT_PASSWORD") : ENV.fetch("AGENT_PASSWORD", "kahya-local-dev")
manager_password = Rails.env.production? ? ENV.fetch("MANAGER_PASSWORD") : ENV.fetch("MANAGER_PASSWORD", "kahya-local-dev")
cfo_password = Rails.env.production? ? ENV.fetch("CFO_PASSWORD") : ENV.fetch("CFO_PASSWORD", "kahya-local-dev")

# Mevcut temsilci hesabını taşı (idempotent, ikinci kullanıcı oluşmaz):
old_agent = User.find_by(email_address: "agent@tempodesk.example")
old_agent&.update!(email_address: "agent@kahya.example")

agent_user = User.find_or_create_by!(email_address: "agent@kahya.example") do |u|
  u.password = agent_password
  u.role = :agent
end
agent_user.update_column(:role, User.roles[:agent]) if agent_user.role.blank?

manager_user = User.find_or_create_by!(email_address: "manager@kahya.example") do |u|
  u.password = manager_password
  u.role = :manager
end
manager_user.update_column(:role, User.roles[:manager]) unless manager_user.role_manager?

cfo_user = User.find_or_create_by!(email_address: "cfo@kahya.example") do |u|
  u.password = cfo_password
  u.role = :cfo
end
cfo_user.update_column(:role, User.roles[:cfo]) unless cfo_user.role_cfo?

# ------------------------------------------------------------------------------
# 2. Örnek Destek Biletleri (Geriye Dönük Uyumluluk)
# ------------------------------------------------------------------------------
# Bilet 1: Acil & Süresi Dolmuş (SLA İhlali - Açık)
t1 = Ticket.find_or_create_by!(title: "Ödeme Geçidi Kesintisi (SLA İhlali)") do |t|
  t.description = "Müşterilerimiz ödeme aşamasında 500 sunucu hatası alıyor. Kart çekim işlemleri tamamen durdu, acil müdahale gerekiyor."
  t.customer_email = "ayse.yilmaz@fintech.example"
  t.priority = :urgent
  t.status = :open
  t.created_at = 2.days.ago
  t.due_at = SlaPolicy.due_at(priority: :urgent, from: 2.days.ago)
end

t1.comments.find_or_create_by!(
  author_role: :customer,
  author_name: "Ayşe Yılmaz",
  body: "Ödeme altyapımız tamamen durdu, müşteriler sepeti terk ediyor. Lütfen acil destek!"
) do |c|
  c.created_at = 2.days.ago + 10.minutes
end

t1.comments.find_or_create_by!(
  author_role: :agent,
  author_name: "Destek Temsilcisi",
  body: "Bildiriminiz alındı. Altyapı ve ağ ekibine bilgi verildi, loglar inceleniyor."
) do |c|
  c.created_at = 2.days.ago + 25.minutes
end

# Bilet 2: Yüksek Öncelikli & Zamanında Çözülmüş (SLA İhlalsiz)
t2 = Ticket.find_or_create_by!(title: "Kullanıcı Yetkilendirme ve Rol Hatası") do |t|
  t.description = "Yeni eklenen departman yöneticileri yönetim paneline erişirken 403 Forbidden alıyor."
  t.customer_email = "mehmet.kaya@holding.example"
  t.priority = :high
  t.status = :solved
  t.created_at = 1.day.ago
  t.due_at = SlaPolicy.due_at(priority: :high, from: 1.day.ago)
  t.solved_at = 1.day.ago + 3.hours
  t.resolution_summary = "Rol matrisi tablosunda eksik olan 'departman_yoneticisi' yetki grubu Active Directory eşlemesiyle senkronize edildi. Etkilenen 5 kullanıcının oturumları yenilendi ve erişim sağlandı."
end
t2.update_column(:resolution_summary, "Rol matrisi tablosunda eksik olan 'departman_yoneticisi' yetki grubu Active Directory eşlemesiyle senkronize edildi. Etkilenen 5 kullanıcının oturumları yenilendi ve erişim sağlandı.") if t2.resolution_summary.blank?

t2.comments.find_or_create_by!(
  author_role: :customer,
  author_name: "Mehmet Kaya",
  body: "5 yeni yöneticimiz panellere giremiyor, toplantı öncesi acil yetki tanımlanması gerekiyor."
) do |c|
  c.created_at = 1.day.ago + 5.minutes
end

t2.comments.find_or_create_by!(
  author_role: :agent,
  author_name: "Destek Temsilcisi",
  body: "Rol matrisi tablosunda eksik olan izinler güncellendi. Yöneticileriniz artık giriş yapabilir."
) do |c|
  c.created_at = 1.day.ago + 3.hours
end

# Bilet 3: Normal Öncelikli & Yeni Açılmış
t3 = Ticket.find_or_create_by!(title: "Fatura Bilgisi ve Unvan Güncelleme Talebi") do |t|
  t.description = "Şirketimizin resmi unvanı ve vergi dairesi değişti. Sonraki faturaların yeni şirket unvanına kesilmesini istiyoruz."
  t.customer_email = "muhasebe@tedarik.example"
  t.priority = :normal
  t.status = :new
  t.created_at = 2.hours.ago
  t.due_at = SlaPolicy.due_at(priority: :normal, from: 2.hours.ago)
end

t3.comments.find_or_create_by!(
  author_role: :customer,
  author_name: "Ahmet Muhasebe",
  body: "Yeni vergi levhası ve ticaret sicil gazetesi bilgileri güncellendi."
) do |c|
  c.created_at = 2.hours.ago + 2.minutes
end

# Bilet 4: Acil & Çözülmüş-Geç
t4 = Ticket.find_or_create_by!(title: "Veritabanı Replikasyon Gecikmesi") do |t|
  t.description = "İkincil PostgreSQL düğümünde 45 dakikalık replikasyon gecikmesi oluştu, okuma sorguları eski veri dönüyor."
  t.customer_email = "devops@bulut.example"
  t.priority = :urgent
  t.status = :solved
  t.created_at = 3.days.ago
  t.due_at = SlaPolicy.due_at(priority: :urgent, from: 3.days.ago)
  t.solved_at = 3.days.ago + 10.hours
  t.resolution_summary = "İkincil düğümdeki disk I/O darboğazı WAL prosesini kilitliyordu. max_wal_size ve checkpoint aralığı optimize edildi, replikasyon gecikmesi sıfırlandı."
end
t4.update_column(:resolution_summary, "İkincil düğümdeki disk I/O darboğazı WAL prosesini kilitliyordu. max_wal_size ve checkpoint aralığı optimize edildi, replikasyon gecikmesi sıfırlandı.") if t4.resolution_summary.blank?

t4.comments.find_or_create_by!(
  author_role: :customer,
  author_name: "Caner DevOps",
  body: "Replikasyon kuyruğu giderek şişiyor, IOPS değerleri tavan yaptı."
) do |c|
  c.created_at = 3.days.ago + 5.minutes
end

t4.comments.find_or_create_by!(
  author_role: :agent,
  author_name: "Destek Temsilcisi",
  body: "Disk I/O darboğazı giderildi, WAL segmentleri senkronize edildi ve gecikme sıfırlandı."
) do |c|
  c.created_at = 3.days.ago + 10.hours
end

# Bilet 5: Düşük Öncelikli & Açık
t5 = Ticket.find_or_create_by!(title: "Karanlık Tema Tercihi Önerisi") do |t|
  t.description = "Gece vardiyasında çalışan destek ekiplerimiz için arayüze koyu tema seçeneği getirilmesini rica ediyoruz."
  t.customer_email = "selin.tas@tasarim.example"
  t.priority = :low
  t.status = :open
  t.created_at = 6.hours.ago
  t.due_at = SlaPolicy.due_at(priority: :low, from: 6.hours.ago)
end

t5.comments.find_or_create_by!(
  author_role: :customer,
  author_name: "Selin Taş",
  body: "Özellikle bilet detay sayfasında yüksek kontrastlı karanlık mod göz yorgunluğunu azaltacaktır."
) do |c|
  c.created_at = 6.hours.ago + 10.minutes
end

t5.comments.find_or_create_by!(
  author_role: :agent,
  author_name: "Destek Temsilcisi",
  body: "Değerli geri bildiriminiz için teşekkürler. Talep ürün geliştirme yol haritasına eklendi."
) do |c|
  c.created_at = 4.hours.ago
end

# Bilet 6: Normal Öncelikli & Kapatılmış Bilet
t6 = Ticket.find_or_create_by!(title: "E-Posta Bildirim Şablonu Güncellemesi") do |t|
  t.description = "Eski kurumsal logomuz bildirim e-postalarında kalmış, yenilendi."
  t.customer_email = "iletisim@ajans.example"
  t.priority = :normal
  t.status = :open
  t.created_at = 5.days.ago
  t.due_at = SlaPolicy.due_at(priority: :normal, from: 5.days.ago)
end

if t6.status_open?
  t6.comments.find_or_create_by!(
    author_role: :customer,
    author_name: "Ali İletişim",
    body: "E-posta şablonundaki eski logo dosyasını güncelledim."
  ) do |c|
    c.created_at = 5.days.ago + 1.hour
  end

  t6.comments.find_or_create_by!(
    author_role: :agent,
    author_name: "Destek Temsilcisi",
    body: "Şablonlar kontrol edildi ve onaylandı. Bilet kapatılmıştır."
  ) do |c|
    c.created_at = 5.days.ago + 12.hours
  end

  t6.update_columns(
    status: Ticket.statuses[:closed],
    solved_at: 5.days.ago + 12.hours,
    resolution_summary: "E-posta bildirim şablonundaki tüm eski varlıklar yeni CDN bağlantılarıyla değiştirildi, test gönderimleri onaylandı."
  )
end

# ------------------------------------------------------------------------------
# 3. Kâhya Harcama Denetimi Sentetik Verileri (Faz 1)
# ------------------------------------------------------------------------------
# 1. Otomatik Onaylı (Tutar limiti altı, düşük risk, LLM tarafından onaylanmış)
e1 = Expense.find_or_create_by!(
  merchant: "OfisDepo Kırtasiye Ltd.",
  category: "Ofis Malzemeleri",
  amount_cents: 45_000
) do |e|
  e.description = "Temsilci ve operasyon ekibi için ergonomik klavye ve fare seti alımı"
  e.spent_on = 2.days.ago.to_date
  e.submitted_by = "ProcurementBot"
  e.status = :approved
  e.approver_role = :manager
  e.review_due_at = ExpensePolicy.review_due_at(from: 2.days.ago)
  e.verdict = "approve"
  e.risk_score = 8
  e.policy_clause = "Madde 1: Ofis sarf malzemeleri 1.000 TL altında doğrudan onaylanır"
  e.llm_reason = "Harcama tutarı otomatik onay sınırının altında ve onaylı kategoriye uygundur."
  e.decided_by = "llm"
  e.decided_at = 2.days.ago + 5.minutes
  e.created_at = 2.days.ago
end

e1.expense_events.find_or_create_by!(
  actor: "llm",
  action: "approved"
) do |ev|
  ev.reason = "Politika kuralı gereği otomatik onaylandı"
  ev.created_at = 2.days.ago + 5.minutes
end

# 2. Gri Alanda Bekleyen (Yönetici İncelemesinde, Süresi Var)
e2 = Expense.find_or_create_by!(
  merchant: "Akdeniz Balıkçısı",
  category: "Temsil ve Ağırlama",
  amount_cents: 280_000
) do |e|
  e.description = "Yurt dışı iş ortağı teknik heyeti ile akşam yemeği"
  e.spent_on = Date.current
  e.submitted_by = "TravelAgent"
  e.status = :pending_review
  e.approver_role = :manager
  e.review_due_at = ExpensePolicy.review_due_at(from: 4.hours.ago)
  e.verdict = "flag"
  e.risk_score = 62
  e.policy_clause = "Madde 4: Temsil ve ağırlama harcamalarında kişi başı limit aşımı yönetici incelemesi gerektirir"
  e.llm_reason = "Kişi başı harcama limiti sınırda görüldü, harcamanın iş gerekçesi yönetici tarafından incelenmeli."
  e.created_at = 4.hours.ago
end

e2.expense_events.find_or_create_by!(
  actor: "agent",
  action: "submitted"
) do |ev|
  ev.reason = "API üzerinden harcama iletildi, LLM inceleme için bayrak ekledi"
  ev.created_at = 4.hours.ago
end

# 3. 30 Saat Önce Açılıp Eskale Olmuş (CFO'ya Eskale, review_due_at açıkça verilir)
e3 = Expense.find_or_create_by!(
  merchant: "Amazon Web Services",
  category: "Bulut Altyapısı",
  amount_cents: 350_000
) do |e|
  e.description = "Geliştirme ortamı GPU sunucu rezervasyon taahhüt ücreti"
  e.spent_on = 2.days.ago.to_date
  e.submitted_by = "DevOpsAgent"
  e.status = :pending_review
  e.approver_role = :manager
  e.created_at = 30.hours.ago
  e.review_due_at = 6.hours.ago # 30 hours ago + 24 hours = 6 hours ago
  e.verdict = "flag"
  e.risk_score = 58
  e.policy_clause = "Madde 6: Rezervasyon harcamalarında taahhüt süresi incelemesi"
  e.llm_reason = "Yıllık taahhüt içerdiğinden yönetici onayına yönlendirildi; süre dolumu nedeniyle CFO eskalasyonuna girdi."
end

e3.expense_events.find_or_create_by!(
  actor: "agent",
  action: "submitted"
) do |ev|
  ev.reason = "API üzerinden harcama iletildi"
  ev.created_at = 30.hours.ago
end

# 4. Yüksek Tutarlı Doğrudan CFO'ya Giden (Tutar CFO Eşiği Üzerinde)
e4 = Expense.find_or_create_by!(
  merchant: "Apple Yetkili Satıcı",
  category: "Donanım",
  amount_cents: 850_000
) do |e|
  e.description = "Yeni baş mühendis için MacBook Pro iş istasyonu alımı"
  e.spent_on = Date.current
  e.submitted_by = "ITSupportBot"
  e.status = :pending_review
  e.approver_role = :cfo
  e.review_due_at = ExpensePolicy.review_due_at(from: 2.hours.ago)
  e.verdict = "flag"
  e.risk_score = 74
  e.policy_clause = "Madde 2: 5.000 TL üzeri harcamalar doğrudan CFO onayına tabidir"
  e.llm_reason = "Tutar doğrudan CFO onay sınırının üzerinde olduğundan üst kurula yönlendirildi."
  e.created_at = 2.hours.ago
end

e4.expense_events.find_or_create_by!(
  actor: "agent",
  action: "submitted"
) do |ev|
  ev.reason = "API üzerinden harcama iletildi, CFO onayına yönlendirildi"
  ev.created_at = 2.hours.ago
end

# 5. Reddedilmiş Harcama (Yönetici Tarafından Reddedilmiş)
e5 = Expense.find_or_create_by!(
  merchant: "Steam Oyun Mağazası",
  category: "Yazılım",
  amount_cents: 180_000
) do |e|
  e.description = "Ekip içi cuma günü oyun seansı için çok oyunculu lisans alımı"
  e.spent_on = 3.days.ago.to_date
  e.submitted_by = "TeamLeadBot"
  e.status = :rejected
  e.approver_role = :manager
  e.review_due_at = ExpensePolicy.review_due_at(from: 3.days.ago)
  e.verdict = "flag"
  e.risk_score = 92
  e.policy_clause = "Madde 8: Şirket kredi kartıyla eğlence ve oyun yazılımı alımı yasaktır"
  e.llm_reason = "Kişisel eğlence amaçlı harcama tespiti."
  e.decided_by = "manager"
  e.decided_at = 2.days.ago + 1.hour
  e.created_at = 3.days.ago
end

e5.expense_events.find_or_create_by!(
  actor: "manager",
  action: "rejected"
) do |ev|
  ev.reason = "Şirket politikasının 8. maddesi uyarınca eğlence harcamaları onaylanamaz"
  ev.created_at = 2.days.ago + 1.hour
end
