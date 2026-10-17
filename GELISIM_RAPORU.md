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

---

### Aşama 7: CI ve Deploy Hazırlığı
- **Shebang ve İzin Standartlaştırması:** Windows üzerinde Rails üreteçlerinin oluşturduğu `#!/usr/bin/env ruby.exe` shebang'leri Linux runner'lar için `#!/usr/bin/env ruby` olarak düzeltildi; tüm `bin/*` dosyalarının git çalıştırma izinleri (`100755`) ayarlandı.
- **GitHub Actions CI (`.github/workflows/ci.yml`):**
  - PostgreSQL 16 servisi (`postgres:16`, `POSTGRES_DB: tempodesk_test`, `POSTGRES_PASSWORD: postgres`) eklendi.
  - `main` dalına push ve PR tetikleyicileri ayarlandı.
  - `scan_ruby` (brakeman), `lint` (rubocop), `test` (minitest), `scan_js` (importmap audit) ve `system-test` adımlarının tamamı **%100 yeşil** çalıştırıldı.
  - CI durumu için `README.md`'ye resmi GitHub Actions rozeti eklendi.
- **Render & Docker Hazırlığı:**
  - `bin/docker-entrypoint` içine `./bin/rails db:prepare` ve `./bin/rails db:seed` komutları eklendi.
  - `db/seeds.rb` dosyasının `production` ortamında `AGENT_PASSWORD` tanımlı olmadığında güvenli hata fırlattığı kanıtlandı.
  - `config/environments/production.rb` içinde Render proxy'si için SSL zorunluluğu açılırken, Render'ın düz HTTP ile attığı sağlık kontrollerinin 301 yönlendirmesine takılmaması için `ssl_options` ile `/up` hariç tutuldu.
- **Commit:** `468e27c` ve `1516e10` — *Stage 7: Production-ready CI with PostgreSQL, Docker seed, SSL config, and CI badge*

---

### Aşama 8: Kullanıcı Acısı — Kalıcı Çözüm Özeti (Resolution Summary)
- **Kullanıcı Acısı Tespiti:** G2 ve Capterra'da önde gelen destek masası yazılımlarına yönelik en yaygın şikayetlerden biri incelendi: *"Bilet kapandığında veya çözüldüğünde asıl çözümün ne olduğu 15 mesajlık konuşma geçmişinin içinde kayboluyor; hem müşteri hem de yeni temsilci çözümü bulmak için tüm geçmişi okumak zorunda kalıyor."*
- **Veritabanı & Model:**
  - `tickets` tablosuna `resolution_summary: text` kolonu eklendi (Migration: `20261017162653_add_resolution_summary_to_tickets.rb`).
  - `Ticket#transition_to!` metodu isteğe bağlı `resolution_summary` parametresi alacak şekilde güncellendi.
- **Temsilci Arayüzü (`app/views/agent/tickets/show.html.erb`):**
  - Temsilcinin tek tıkla doğrudan çözebileceği gibi, `<details><summary>` ile açılan şık bir açılır menüde kalıcı çözüm notu yazarak çözebileceği esnek arayüz geliştirildi.
  - Çözülmüş biletlerde en üstte belirgin zümrüt yeşili "Kalıcı Çözüm Özeti" kartı yerleştirildi.
- **Müşteri Arayüzü (`app/views/tickets/show.html.erb`):**
  - Müşteri gizli takip sayfasında bilet çözüldüğünde çözüm özeti varsa en üstte teşekkür ve bilgilendirme kartı olarak gösterildi.
- **Tasarım & Mobil Uyum:** Harici CSS kütüphanesi olmadan Vanilla CSS ile `.resolution-summary-box`, `.resolve-details` sınıfları yazıldı; mobil ekranda taşma yapmadığı test edildi.
- **Commit:** `1de1835` — *Stage 8: Resolution summary feature (user pain solved) with models, views, seeds and tests*

---

### Aşama 9: Canlı Yayın (Render Deploy)
- **Canlı Adres:** [https://tempodesk.onrender.com/](https://tempodesk.onrender.com/)
- **Altyapı:** Render Web Service (Docker Runtime) + Render PostgreSQL Managed Database.
- **Otomatik Başlangıç:** Konteyner ayağa kalkarken `bin/docker-entrypoint` otomatik olarak migrasyonları ve seed biletlerini yükledi.
- **Canlı Doğrulama:**
  - `https://tempodesk.onrender.com/up` → HTTP 200 OK
  - `https://tempodesk.onrender.com/` → Müşteri bilet açma formu başarıyla yüklendi.
  - `https://tempodesk.onrender.com/session/new` → Temsilci giriş ekranı doğrulandı.

---

## 📊 Doğrulama ve Test Özeti

### 1. Test Paketi Durumu
```text
Running 53 tests in a single process (parallelization threshold is 100)
Run options: --seed 28414

# Running:
.....................................................

Finished in 2.841528s, 18.6519 runs/s, 80.2385 assertions/s.
53 runs, 228 assertions, 0 failures, 0 errors, 0 skips
```
*Tüm model, SLA zaman kuralı (`travel_to`), müşteri entegrasyonu, temsilci portalı ve çözüm özeti testleri %100 yeşildir.*

### 2. GitHub Actions CI Durumu
- **İş Akışı:** `.github/workflows/ci.yml`
- **Rozet:** [![CI](https://github.com/mustafa-karakoyun/TempoDesk/actions/workflows/ci.yml/badge.svg)](https://github.com/mustafa-karakoyun/TempoDesk/actions/workflows/ci.yml)
- **Tüm İşler:** `scan_ruby` (yeşil), `lint` (yeşil), `test` (yeşil), `scan_js` (yeşil), `system-test` (yeşil).

### 3. Marka Kuralı Taraması
```powershell
Get-ChildItem -Recurse -File -Exclude README.md | Select-String -Pattern "<marka_kuralı_deseni>" -List | Where-Object { $_.Path -notmatch "\\\.git\\|node_modules|\\log\\|\\tmp\\" }
```
*Sonuç: 0 eşleşme (orijinal marka adı kod tabanında, dosya adlarında ve şablonlarda kesinlikle bulunmamaktadır).*

### 4. Çalışır Durumdaki Ekranlar
- **Canlı Uygulama (Render):** [https://tempodesk.onrender.com/](https://tempodesk.onrender.com/)
- **Canlı Temsilci Girişi:** [https://tempodesk.onrender.com/session/new](https://tempodesk.onrender.com/session/new) (`agent@tempodesk.example`)
- **Canlı Sağlık Kontrolü:** [https://tempodesk.onrender.com/up](https://tempodesk.onrender.com/up) (200 OK)
- **Yerel Uygulama:** `http://localhost:3000/`

---

## 🏁 Sonuç

TempoDesk aort dilimi projesi; gereksiz özelliklerden arındırılmış, yüksek test güvencesine sahip, gerçek bir kullanıcı acısını çözen kalıcı çözüm özetini barındıran, CI/CD'si eksiksiz çalışan ve Render üzerinde canlıda hizmet veren kurumsal bir Rails 8 uygulaması olarak başarıyla tamamlanmıştır.
