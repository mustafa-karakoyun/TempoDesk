# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# ------------------------------------------------------------------------------
# 1. Demo Temsilci Hesabı
# ------------------------------------------------------------------------------
# Şifre ENV["AGENT_PASSWORD"]'dan gelir.
# Production'da değişken yoksa seed KeyError ile durur (bilinen bir varsayılan şifreyle canlı hesap açılmasın).
# Yerel varsayılan yalnızca development ve test içindir.
agent_password =
  if Rails.env.production?
    ENV.fetch("AGENT_PASSWORD")
  else
    ENV.fetch("AGENT_PASSWORD", "tempodesk-local-dev")
  end

User.find_or_create_by!(email_address: "agent@tempodesk.example") do |user|
  user.password = agent_password
end

# ------------------------------------------------------------------------------
# 2. Örnek Destek Biletleri (Aşama 6 Kriterleri)
# ------------------------------------------------------------------------------
# Kurallar:
# (1) find_or_create_by! ile idempotent (tekrar çalıştırıldığında kayıt çoğalmaz).
# (2) Süresi dolmuş biletlerde created_at ve due_at açıkça verilir (SlaPolicy.due_at(..., from: X.days.ago)).
# (3) Seed içinde travel_to kullanılmaz.

# Bilet 1: Acil & Süresi Dolmuş (SLA İhlali - Açık)
# 2 gün önce açılmış, 4 saatlik SLA süresi dolmuş, listede kırmızı SLA ihlali rozetiyle en başta görünmeli.
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
# 1 gün önce açılmış, 8 saatlik SLA taahhüdü var, 3 saatte çözülmüş (yeşil SLA rozeti).
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

# Bilet 3: Normal Öncelikli & Yeni Açılmış (Temsilci Henüz Yanıtlamamış)
# 2 saat önce açılmış, 24 saatlik SLA taahhüdü var, 22 saati kalmış (Yeni durumu).
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

# Bilet 4: Acil & Çözülmüş-Geç (SLA İhlalli Çözüm)
# 3 gün önce açılmış, 4 saatlik SLA taahhüdü var, 10 saatte çözülmüş (kırmızı 'geç çözüldü' rozeti).
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

# Bilet 5: Düşük Öncelikli & Açık (Bolca Süresi Olan Bilet)
# 6 saat önce açılmış, 48 saatlik SLA süresi var, ~42 saati kalmış (Açık durumu).
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
# 5 gün önce açılmış, çözülmüş ve sonrasında kapatılmış bilet (artık yeni yanıt eklenemez).
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
