# TempoDesk

[![CI](https://github.com/mustafa-karakoyun/TempoDesk/actions/workflows/ci.yml/badge.svg)](https://github.com/mustafa-karakoyun/TempoDesk/actions/workflows/ci.yml)

> Kurumsal Destek Masası (Helpdesk) & SLA Yönetimi Aort Dilimi  
> **Teknoloji:** Ruby on Rails 8, PostgreSQL, Minitest, Sade ERB + Vanilla CSS  
> **GitHub Deposu:** [https://github.com/mustafa-karakoyun/TempoDesk](https://github.com/mustafa-karakoyun/TempoDesk)

---

## 1. Faz 1 - Genel SaaS & Fortune 500 Tablosu

Aşağıdaki tablo, Fortune 500 şirketlerinin genel büyüklük ölçeğini ve SaaS kullanım dinamiklerini göstermektedir:

| Kriter | Değer / Aralık | Kaynak Linki (Açık Erişim) |
| :--- | :--- | :--- |
| **a. Değerleme / Gelir Aralığı** | $7.47 Milyar (Resideo Tech.) — $716.92 Milyar (Amazon) | [US500 - Fortune 500 Şirket Listesi](https://us500.com/fortune-500-companies) |
| **b. Çalışan Sayısı Aralığı** | 14.800 çalışan (Resideo Tech.) — 1.58 Milyon çalışan (Amazon) | [US500 - Fortune 500 Şirket Listesi](https://us500.com/fortune-500-companies) |
| **c. Firma Başı SaaS Sayısı** | Kurumsal ölçekte ortalama **247 – 323 adet SaaS** | [Zylo SaaS Management Index](https://zylo.com/blog/saas-spend-management) & [Okta Businesses at Work](https://www.okta.com/blog/product-innovation/unlock-saas-growth-with-enterprise-ready-identity/) |
| **d. Yıllık SaaS Harcaması** | Firma başı yıllık ortalama **$55.8 Milyon+** | [Zylo SaaS Spend Management Raporu](https://zylo.com/blog/saas-spend-management) |

---

## 2. SaaS Seçimi ve Fortune 500 Kanıtı

- **Seçilen SaaS:** Zendesk (Destek ve Bilet Yönetim Platformu)
- **Kullanan Firma:** Uber Technologies
- **Müşteri Kanıtı:** Zendesk’in müşteri hikâyesine göre Uber, 2010'dan beri Zendesk Support kullanıyor.: [Zendesk Resmi Uber Vaka Analizi](https://www.zendesk.com/customer/uber/)
- **Fortune 500 Doğrulaması:** Uber Technologies, Fortune 500 listesinde #92 sıradadır: [Fortune Şirket Profili](https://fortune.com/company/uber-technologies/)
- **Ek Kurumsal Kanıt:** Siemens Financial Services (600+ lisans): [Siemens Financial Services](https://ultimate.ai/customer-stories/siemens)

---

## 3. Faz 2 - Maliyet ve Kod Hacmi Tahmini

### a. Zendesk Satır Sayısı Tahmini ve Yöntem
- **Referans Açık Kaynak Analizi:** Zendesk mühendisleri Cristian Planas ve Anatoly Mikhaylov, EuRuKo 2024 konuşmasında
(13 Eylül 2024, video 18:57-19:02) monolitte ve özel gem'lerde 1,6 milyon satırın
üzerinde kod olduğunu söylüyor. Kaynak: [Zendesk EuRuKo 2024](https://www.youtube.com/watch?v=2nmgfVqhfiw&t=1149s)

### b. Maliyet ve Süre Tahmini

| Kalem | Tahmin | Gerçekleşen |
| :--- | :--- | :--- |
| **Tüm çekirdek (~300k satır): maliyet** | $742 – $2.228 | Yapılmadı (Kapsam dışı tahmin) |
| **Tüm çekirdek: süre** | 60 – 100 iş günü | Yapılmadı (Kapsam dışı tahmin) |
| **Aort dilimi (~1.000 satır): maliyet** | $5 – $10 | *[Dashboard'dan panel tutarı]* |
| **Aort dilimi: süre** | 2 gün (~14 saat) | *[Başlama-bitiş kayıt süresi]* |

**Varsayımlar:**
- **Token Katsayıları:** Satır başına ~11 çıktı token (300k satır = ~3.3M token). Ajan döngüsü çarpanı 3x–5x. Girdi/çıktı oranı bağlam tekrarı nedeniyle 20x–40x.
- **Birim Fiyat:** Anthropic Claude 3.5/3.7 Sonnet resmi API fiyatı (Girdi: $3.00/1M, Çıktı: $15.00/1M). [Anthropic Pricing](https://www.anthropic.com/pricing) (Ekim 2026).
- **Doğrulama Hızı:** Günde 3.000 – 5.000 satır kodun insan mühendis tarafından okunup doğrulanabildiği varsayılmıştır.

### c. Gerçekleşen Harcama Takibi (Kayıt Defteri)
- **Başlangıç:** 16 Ekim 2026 14:00
- **Kullanılan Araç:** Cursor / Antigravity IDE
- **Harcama Kaydı:** Proje bitiminde kullanım panelinden (Usage Dashboard) ekran görüntüsüyle teyit edilerek doldurulacaktır.

---

## 4. Kurulum ve Yerel Çalıştırma

### Gereksinimler
- Ruby 3.4+ / Ruby 4
- PostgreSQL (yerel servis çalışır durumda olmalı)

### Adımlar (Windows PowerShell)
```powershell
# Bağımlılıkları yükleyin
bundle install

# Veritabanını oluşturun, şemayı yükleyin ve demo verisini yükleyin
$env:PGPASSWORD = "postgres_sifreniz"
ruby bin/rails db:create db:migrate db:seed

# Test paketini çalıştırın (50 test, 210 assertion)
ruby bin/rails test

# Sunucuyu başlatın
ruby bin/rails server
```

### Ekranlar ve Erişim
- **Müşteri Bilet Formu:** `http://localhost:3000/`
- **Temsilci Girişi:** `http://localhost:3000/session/new`  
  - *E-posta:* `agent@tempodesk.example`  
  - *Geliştirme Parolası:* `tempodesk-local-dev`
- **Temsilci Bilet Sırası:** `http://localhost:3000/agent/tickets`
- **Sağlık Kontrolü:** `http://localhost:3000/up` (200 OK)

---

## 5. Yapamadıklarım

> Bu bölüm, projenin anayasası gereği gerçek durumu dürüstçe raporlar (17 Ekim 2026 güncel durumu). Kanıtı (test çıktısı, canlı ekran) olmayan hiçbir özellik "çalışıyor" diye raporlanmaz.

### a. Bilerek kapsam dışı bıraktıklarım
Aort dilimi (*Müşteri bilet açar → Temsilci yanıtlar → Çözülür, çözüm süresi SLA'ya göre izlenir*) dışında kalan ve bilerek eklenmeyen unsurlar:
- Raporlama ve istatistik panoları
- Canlı sohbet ve web soketleri
- Bilgi bankası / yardım makaleleri
- Kullanıcı topluluk forumu
- Çoklu dil desteği
- E-posta bildirimi (canlı e-posta sunucusu bağlanmadığı için sahte özellik bırakılmadı)
- Parola sıfırlama (e-posta gönderimi olmadan çalışamayacağı için kaldırıldı)
- Otomatik bilet kapatma zamanlayıcısı
- Canlı JavaScript geri sayım sayaçları (sunucu taraflı hesaplama tercih edildi)
- Mesai saati / hafta sonu takvimi hesabı (SLA yalnızca takvim süresidir)
- Temsilci atama ve çoklu departman hiyerarşisi
- Dosya eki yükleme
- Ödeme veya kart bilgisi akışı

### b. Tamamlananlar (Doğrulanmış Çekirdek Özellikler)
- **Temsilci Kimlik Doğrulama:** Rails 8 yerleşik oturum akışı (`Session` & `User`).
- **Veri Modelleri & Güvenlik:** `Ticket` (güvenli `access_token`, ön ekli enum'lar) ve `Comment` ilişkileri.
- **SLA Motoru (`SlaPolicy`):** Acil (4s), Yüksek (8s), Normal (24s), Düşük (48s) çözüm süreleri tek merkezde. İhlal veritabanında saklanmaz; anlık `Ticket#sla_breached?` ile hesaplanır.
- **Kontrollü Durum Akışı:** `new → open → solved → closed` geçişleri `Ticket#transition_to!` ile yürütülür, yetkisiz geçişler kullanıcıya anlaşılır hata verir.
- **İlk Yanıtta Otomatik Açılma:** Temsilcinin yeni bir bilete ilk yanıtında bilet otomatik olarak `new → open` durumuna geçer.
- **Müşteri Ekranları:** Herkese açık form (`/`), gizli takip bağlantısı (`/t/:access_token`), müşteri yanıt formu.
- **Temsilci Ekranları:** SLA sırasına göre otomatik dizilen operasyonel bilet listesi (`/agent/tickets`), detay sayfası, durum aksiyon butonları.
- **İdempotent Demo Verisi (`db/seeds.rb`):** Tekrar çalıştırıldığında çoğalmayan, SLA senaryolarını (süresi aşılmış acil bilet, zamanında çözülmüş, geç çözülmüş bilet) sergileyen 6 gerçekçi demo bilet.
- **Görsel Tasarım & Mobil Uyumluluk:** Harici CDN/framework bağımlılığı olmayan saf Vanilla CSS tasarım sistemi; tek satır SLA rozetleri, geç çözülen biletler için sönük "Geç çözüldü" rozeti, dar ekranda (375 px) yatay kaydırma yapmayan duyarlı kart düzeni.
- **Otomatik Testler:** Model, SLA zaman kuralları (`travel_to`), müşteri ve temsilci akışları ile çözüm özeti testlerini kapsayan 53 testin tamamı (%100) yeşildir.
- **GitHub Actions CI (Aşama 7):** `.github/workflows/ci.yml` iş akışı GitHub Actions üzerinde başarıyla çalışmakta ve tüm kontroller (`scan_ruby`, `lint`, `test`, `scan_js`, `system-test`) **%100 yeşil (passing)** olarak doğrulanmaktadır.
- **Kullanıcı Acısı Çözüm Özelliği (Aşama 8):** G2/Capterra Zendesk incelemelerinde en çok yakınılan "Çözümün nasıl sağlandığı karmaşık mesaj geçmişinde kayboluyor" acısını çözen **Kalıcı Çözüm Özeti (Resolution Summary)** özelliği eklendi. Temsilci bileti çözerken çözüm özeti girebilir; bilet çözüldüğünde bu özet hem müşterinin takip sayfasında hem de temsilci panelinde en üstte belirgin yeşil bilgi kartı olarak sunulur.

### c. Henüz yapılmayanlar (Yalnızca Render Canlı Deploy)
- **Canlı Deploy (Render):** Canlı URL henüz yoktur. Render PostgreSQL ve Docker konfigürasyonu insan tarafından panelden yapılacaktır.

### d. Doğrulanmayanlar ve bilinen konular
- Render'da `AGENT_PASSWORD`, `DATABASE_URL` ve `RAILS_MASTER_KEY` ayarları, Render'ın ücretsiz planındaki kısıtlar ve `Dockerfile`'ın Render'da çalışıp çalışmadığı henüz canlıda test edilmedi.
- Ruby 4.0.7 ile Rails'in ürettiği `bin/kamal` çalışmıyor (`fiddle` bağımlılığı). Deploy Render'da Docker ile yapılacağı için Kamal kullanılmayacaktır.
- Geliştirme ortamı Windows'tur, deploy ortamı Linux konteynerdir. Satır sonlarının LF olduğu `.gitattributes` ile güvenceye alınmıştır.