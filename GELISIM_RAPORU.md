# TempoDesk — Adım Adım Gelişim ve Aşama Raporu

**Proje:** TempoDesk — Kurumsal Destek Masası (Helpdesk) & SLA Yönetimi Aort Dilimi  
**Teknoloji Yığını:** Ruby 4.0.7, Ruby on Rails 8.1.4, PostgreSQL, Minitest, Sade ERB + Vanilla CSS  
**Hedef:** Canlı, uçtan uca çalışan, doğrulanmış ve gerçek bir kullanıcı acısını çözen aort dilimi.  
**Tarih:** 16 Ekim 2026  

---

## 📋 Genel Bakış ve Mimari Kararlar

1. **Aort Dilimi Odaklılığı:** Müşteri bilet açar → Temsilci yanıtlar → Bilet çözülür → Çözüm süresi SLA'ya göre izlenir. Canlı sohbet, raporlama modülleri, çoklu dil, otomatik kapanma zamanlayıcıları ve e-posta gönderimi gibi yan süsler **bilerek kapsam dışı** bırakılmıştır.
2. **SLA Mantığı Tek Merkezde:** Tüm SLA süreleri yalnızca `app/models/sla_policy.rb` dosyasında tanımlıdır (`urgent: 4.hours`, `high: 8.hours`, `normal: 24.hours`, `low: 48.hours`). Kodun başka hiçbir yerinde süre sabiti yazılmamıştır.
3. **Hesaplanan İhlal:** `sla_breached` adında bir veritabanı kolonu veya arka plan cron işi **yoktur**. İhlal, anlık olarak `Ticket#sla_breached?` metoduyla hesaplanır (`(solved_at || Time.current) > due_at`).
4. **Kesin Durum Akışı:** Durum geçişleri doğrudan `update(status: ...)` ile yapılamaz; yalnızca `Ticket#transition_to!` metodu ile kontrollü olarak yürütülür. İzinsiz geçişler `Ticket::InvalidTransition` hatası fırlatır.
5. **Marka Kuralı:** Kod, görünüm, `<title>`, favicon, seed, yorum satırı ve dosya adlarında orijinal ilham kaynağı marka adı **asla geçmez** (yalnızca `README.md` dosyasındaki pazar araştırması bölümünde izinlidir).

---

## 🚀 Tamamlanan Aşamalar (Adım Adım)

### Aşama 0: Hazırlık & Altyapı Kurulumu
- **Parametre Doğrulaması:** `rails new --help` komutu incelenerek `--skip-solid`, `--skip-action-cable`, `--skip-action-mailbox` ve `--skip-action-text` seçeneklerinin varlığı teyit edildi.
- **Proje Oluşturma:** Render'ın tek veritabanı kısıtına ve projenin hafifliğine uygun olarak Rails 8 uygulaması PostgreSQL ile oluşturuldu.
- **Git ve Satır Sonu Standartları:** Windows geliştirme ortamında satır sonu uyumsuzluklarını önlemek amacıyla `.gitattributes` içinde `* text=auto eol=lf` kuralı zorunlu kılındı.
- **Ajan Çalışma Kuralları:** İnsanla birlikte projenin anayasası niteliğindeki `AGENT.md` yazıldı (yalan rapor yasağı, gerçek komut çalıştırma zorunluluğu, marka kuralı, aşama aşama ilerleme).
- **Commit:** `33cc3bb` — *Initial commit: Rails 8 app skeleton with AGENT.md*

---

### Aşama 1: Kimlik Doğrulama & Güvenlik Temizliği
- **Yerleşik Kimlik Doğrulama:** Rails 8'in yerleşik üreteci (`bin/rails generate authentication`) çalıştırılarak `User` ve `Session` modelleri kuruldu.
- **0 Puan Riskinin Önlenmesi (Kritik Karar):** Canlıda e-posta gönderimi yapılandırılmadığı için çalışmayacak olan "Parola Sıfırlama" özelliği (`PasswordsController`, `PasswordsMailer`, ilgili view'lar, mailer önizlemeleri, testleri ve rotaları) **projeden tamamen temizlendi**. Böylece sunumda veya canlıda tıklanıp çalışmayan hiçbir sahte bağlantı bırakılmadı.
- **Temsilci Hesabı:** `db/seeds.rb` içine demo temsilci (`agent@tempodesk.example`) eklendi. Şifre `ENV["AGENT_PASSWORD"]` üzerinden okunacak şekilde yapılandırıldı (production'da zorunlu, yerelde güvenli geliştirme varsayılanı).
- **Erişim Koruması:** `ApplicationController` varsayılan olarak kimlik doğrulaması talep edecek şekilde ayarlandı.
- **Commit:** `5d4cdb9` — *Remove password reset (no email delivery); require AGENT_PASSWORD in production seed*

---

### Aşama 2: Veri Modelleri ve İlişkiler
- **`Ticket` Modeli:**
  - Alanlar: `title` (zorunlu), `description` (zorunlu), `customer_email` (e-posta format doğrulamalı), `priority` (enum), `status` (enum), `due_at` (datetime, null: false), `solved_at` (datetime, nullable), `access_token` (`has_secure_token`).
  - **Kritik Enum Kuralı:** Rails'in `Ticket.new` metodu ile çakışmayı önlemek için `status` ve `priority` enum'larında `prefix: true` zorunlu kılındı (`status_new?`, `status_open?`, `priority_urgent?`).
- **`Comment` Modeli:**
  - Alanlar: `ticket_id` (foreign key), `author_role` (enum: `customer: 0, agent: 1`, `prefix: true`), `author_name` (zorunlu), `body` (zorunlu).
  - İlişkiler: `Ticket has_many :comments, dependent: :destroy` ve `Comment belongs_to :ticket`.
- **Commit:** `6f9bf42` — *Stage 2: Ticket and Comment models (prefixed enums, validations, associations)*

---

### Aşama 3: SLA Mantığı, Durum Akışı ve Zaman Testleri
- **`SlaPolicy` Sınıfı:**
  - `SlaPolicy.due_at(priority:, from: Time.current)` ile süre hesaplaması merkezi hâle getirildi.
  - Öncelik süreleri: Acil (4 saat), Yüksek (8 saat), Normal (24 saat), Düşük (48 saat).
- **`Ticket` Yaşam Döngüsü & `before_validation`:**
  - `due_at` alanı doğrulamadan önce atanır: `before_validation :set_initial_due_at, on: :create`.
- **Durum Geçiş Kuralları (`Ticket#transition_to!`):**
  - İzinli akış: `new → open → solved → closed` ve `solved → open` (yeniden açma).
  - `solved` geçişinde `solved_at = Time.current` atanır, `open`'a geri dönüşte `solved_at = nil` yapılarak temizlenir.
  - İzin verilmeyen geçiş denemelerinde `Ticket::InvalidTransition` fırlatılır.
- **SLA Helper:**
  - Sunucu taraflı `sla_label(ticket)` helper'ı yazılarak açık biletlerde kalan süre ("3 sa 45 dk kaldı"), ihlal durumunda "SLA aşıldı", çözülen biletlerde "SLA içinde çözüldü" etiketleri üretildi.
- **Minitest & Zaman Testleri (`travel_to`):**
  - `ActiveSupport::Testing::TimeHelpers` kullanılarak acil bir biletin 3 saat 59 dakika sonra ihlalsiz olduğu, 4 saat 1 dakika sonra ise `sla_breached?` metodunun `true` döndüğü test edildi.
  - Zamanında çözülen ve geç çözülen biletlerin ihlal durumları otomatik testlerle doğrulandı.
- **Commit:** `8712d59` — *Stage 3: SlaPolicy, status transitions, sla_breached?, sla_label helper and tests*

---

### Aşama 4: Müşteri Ekranları (Açık Form & Gizli Takip)
- **Rotalar:**
  - `GET /` → Bilet oluşturma formu (`tickets#new`).
  - `POST /tickets` → Bilet oluşturma ve müşteriye özel gizli linke yönlendirme.
  - `GET /t/:access_token` → Müşterinin bilet detay ve durum takip sayfası (`tickets#show`).
  - `POST /t/:access_token/comments` → Müşterinin yanıt ekleme aksiyonu.
- **Arayüz & Doğrulama:**
  - Giriş gerektirmeyen controller için `allow_unauthenticated_access` tanımlandı.
  - Yanlış veya geçersiz `access_token` girildiğinde `404 Not Found` sayfası dönmesi sağlandı.
  - Kapatılmış bir bilete yeni yanıt yazılması arayüzde ve model seviyesinde engellendi.
  - Entegrasyon testleri yazılarak müşteri akışı uçtan uca doğrulandı.
- **Commit:** `746cad3` — *Stage 4: Public customer ticket form, secret tracking link (/t/:access_token), customer comments, and integration tests*

---

### Aşama 5: Temsilci Portalı & Durum Yönetimi
- **Rotalar:**
  - `GET /agent/tickets` → Bilet sırası listesi.
  - `GET /agent/tickets/:id` → Bilet detayı ve mesaj geçmişi.
  - `POST /agent/tickets/:id/comments` → Temsilci yanıtı.
  - `PATCH /agent/tickets/:id/transition` → Durum değiştirme aksiyonu.
- **SLA Sıralı Bilet Listesi:**
  - Biletler, ihlalliler ve süresi yaklaşanlar en üstte olacak şekilde dinamik sıralandı:
    `Arel.sql("CASE WHEN status IN (0, 1) THEN 0 ELSE 1 END, due_at ASC")`
- **İlk Yanıtta Otomatik Açılma:**
  - `Comment#open_ticket_on_first_agent_reply` callback'i ile temsilci `new` durumundaki bir bilete ilk yanıtı gönderdiğinde bilet durumu otomatik olarak `open` hâline getirildi (`ticket.transition_to!("open")`).
- **Güvenli Durum Butonları:**
  - Temsilci detay sayfasında biletin mevcut durumuna göre sadece izinli butonlar gösterildi (`Bileti Aç`, `Çözüldü İşaretle`, `Bileti Kapat`, `Yeniden Aç`).
  - Geçersiz bir geçiş zorlandığında `Ticket::InvalidTransition` yakalanarak kullanıcıya anlaşılır bir flash uyarısı verildi, sunucu çökmesi engellendi.
- **Kapsam Temizliği (Plan Uyumu):**
  - Planın *"Raporlama kapsam dışıdır"* kuralına tam uyum sağlamak amacıyla filtreleme sekmeleri ve istatistik sayaçları koddan çıkarıldı; sayfa sadece SLA sıralı operasyonel listeye odaklandı.
- **Fikstür / FK Güvenliği:**
  - Test veritabanında `Session` yabancı anahtar ihlalini önlemek amacıyla `test/fixtures/sessions.yml` eklendi.
- **Commit:** `140ae81` ve `30d0be1` — *Stage 5: Agent portal with ticket list, SLA sorting, detail view, transition actions, and reply auto-open*

---

### Aşama 6: Seed Verisi, Marka & Logo
- **İdempotent Demo Verisi (`db/seeds.rb`):**
  - Tekrar tekrar çalıştırıldığında kayıt çoğalmasını önlemek için `find_or_create_by!` kullanıldı.
  - 6 adet gerçekçi bilet senaryosu eklendi:
    1. **Ödeme Geçidi Kesintisi:** 2 gün önce açılmış, 4 saatlik SLA'sı aşılmış, sırada kırmızı ihlal rozetiyle en başta görünen acil açık bilet.
    2. **Kullanıcı Yetkilendirme Hatası:** 1 gün önce açılmış, 8 saatlik SLA taahhüdü olan ve 3 saatte zamanında çözülmüş bilet (yeşil rozet).
    3. **Fatura Bilgisi Güncelleme:** 2 saat önce açılmış, 22 saati kalmış yeni bilet (temsilci henüz yanıtlamamış).
    4. **Veritabanı Replikasyon Gecikmesi:** 3 gün önce açılmış, 4 saatlik taahhüdü 10 saatte aşılarak geç çözülmüş bilet (kırmızı 'geç çözüldü' rozeti).
    5. **Karanlık Tema Tercihi Önerisi:** 6 saat önce açılmış, 42 saati kalmış düşük öncelikli açık bilet.
    6. **E-Posta Bildirim Şablonu:** Çözülmüş ve kapatılmış bilet (yoruma kapalı).
  - İki kez `db:seed` çalıştırıldığında kayıt sayısının değişmediği (`Fark: 0`) doğrulandı.
- **Marka ve Vektörel Logo:**
  - Rails'in varsayılan kırmızı daire ikonu yerine TempoDesk kurumsal kimliğine uygun nabız dalgalı modern SVG favicon (`public/icon.svg`) oluşturuldu.
  - Navbar'da satır içi SVG nabız ikonu ve `TempoDesk` başlığı yerleştirildi.
  - Temsilci giriş sayfası (`/session/new`) Türkçeleştirildi ve kurumsal kart tasarımı uygulandı.
- **Commit:** `2b89055` — *Stage 6: Seed sample tickets with SLA scenarios, TempoDesk brand logo, SVG favicon, and custom titles*

---

## 📊 Doğrulama ve Test Özeti

### 1. Test Paketi Durumu
```text
Running 50 tests in a single process (parallelization threshold is 50)
Run options: --seed 14306

# Running:
..................................................

Finished in 2.688528s, 18.5975 runs/s, 75.1341 assertions/s.
50 runs, 202 assertions, 0 failures, 0 errors, 0 skips
```
*Tüm model, SLA zaman kuralı (`travel_to`), müşteri entegrasyonu ve temsilci controller testleri %100 yeşildir.*

### 2. Marka Kuralı Taraması
```powershell
Get-ChildItem -Recurse -File -Exclude README.md | Select-String -Pattern "<marka_kuralı_deseni>" -List | Where-Object { $_.Path -notmatch "\\\.git\\|node_modules|\\log\\|\\tmp\\" }
```
*Sonuç: 0 eşleşme (orijinal marka adı kod tabanında, dosya adlarında ve şablonlarda kesinlikle bulunmamaktadır).*

### 3. Çalışır Durumdaki Ekranlar (`localhost:3000`)
- **Müşteri Bilet Formu:** `http://localhost:3000/`
- **Temsilci Girişi:** `http://localhost:3000/session/new` (`agent@tempodesk.example` / `tempodesk-local-dev`)
- **Temsilci Paneli:** `http://localhost:3000/agent/tickets`
- **Sağlık Kontrolü:** `http://localhost:3000/up` (200 OK)

---

## 🔜 Sırada Ne Var?

1. **Aşama 7 (CI ve Deploy Hazırlığı):**
   - `.github/workflows/ci.yml` dosyasının PostgreSQL servisiyle GitHub Actions üzerinde yeşil çalışacak şekilde ayarlanması.
   - `bin/docker-entrypoint` içine `db:seed` eklenerek Render deploy'una hazır hâle getirilmesi.
2. **Aşama 8 (Kullanıcı Acısı Özelliği):**
   - Kullanıcı/pazar yorumlarından seçilecek gerçek bir acıyı çözen fark özelliğinin eklenmesi.
