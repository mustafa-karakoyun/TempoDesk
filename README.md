### SaaS Seçimi ve Fortune 500 Kanıtı
- **Seçilen SaaS:** Zendesk (destek ve bilet yönetimi)
- **Kullanan firma:** Uber Technologies
- **Kanıt:** Uber, Zendesk Support'u 2010'dan beri kullanıyor (Zendesk müşteri hikâyesi): https://www.zendesk.com/customer/uber/
- **Liste doğrulaması:** Fortune 500 (ABD), 2026, 92 , https://fortune.com/company/uber-technologies/
- **Ek kanıt:** Siemens Financial Services, 600+ lisans: https://ultimate.ai/customer-stories/siemens

# TempoDesk

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

## Faz 2


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
- **Kullanılan Araç:** Cursor / Claude 3.7
- **Harcama Kaydı:** Proje bitiminde kullanım panelinden (Usage Dashboard) ekran görüntüsüyle teyit edilerek doldurulacaktır.

---

## 4. Yapamadıklarım

> Bu bölüm, yazıldığı andaki gerçek durumu anlatır (16 Ekim 2026, Aşama 0 ve Aşama 1 bitmiş). Bir madde yapıldığında kanıtıyla (test çıktısı, canlı URL) birlikte buradan silinir. Kanıtı olmayan hiçbir şey "çalışıyor" diye yazılmaz.

### a. Bilerek kapsam dışı bıraktıklarım
Aort dilimi (bilet aç → temsilci yanıtla → çöz, çözüm süresi SLA'ya karşı izlenir) dışında kalan şunları yapmadım ve yapmayacağım:
- Raporlama
- Canlı sohbet
- Bilgi bankası / makale
- Kullanıcı forumu
- Çoklu dil
- E-posta bildirimi
- Parola sıfırlama (e-posta gönderimi olmadan çalışamayacağı için kaldırıldı)
- Otomatik kapanma (zamanlayıcı)
- Canlı JavaScript geri sayım
- Mesai saati / hafta sonu hesabı (SLA yalnızca takvim süresidir)
- Temsilci atama
- Çoklu temsilci yönetimi
- Dosya eki
- Ödeme / kart akışı

### b. Henüz yapılmayanlar (şu anki durum)
Aşama 0'dan Aşama 6'ya kadar olan tüm çekirdek işlevler tamamlandı:
- Temsilci kimlik doğrulama akışı
- `Ticket` ve `Comment` veri modelleri, SLA zaman kuralları (`SlaPolicy`), durum akışı (`transition_to!`)
- Herkese açık müşteri bilet oluşturma formu (`/`), gizli takip bağlantısı (`/t/:access_token`), müşteri yanıt formu
- Temsilci bilet listesi (`/agent/tickets`), SLA öncelik sıralaması, bilet detayı (`/agent/tickets/:id`), durum değiştirme aksiyonları ve ilk yanıtta otomatik açılma (`new → open`)
- 6 adet gerçekçi örnek demo bilet verisi (idempotent seed: süresi dolmuş acil ihlalli bilet, zamanında çözülmüş, yeni, geç çözülmüş ihlalli, düşük öncelikli ve kapatılmış biletler)
- TempoDesk nabız SVG logosu, favicon (`public/icon.svg`) ve sayfa başlıkları (`<title>`)
- 50 adet otomatik test (model, SLA `travel_to`, müşteri entegrasyonu, temsilci entegrasyonu) yeşil ve doğrulanmış durumdadır.

Aşağıdakiler **henüz yapılmamıştır**:
- GitHub Actions'ta çalışan CI ve README'deki CI rozeti (Aşama 7)
- Canlı uygulama (Render). **Canlı URL şu an yoktur.** (Aşama 7)
- Kullanıcı yorumlarından seçilen acıyı çözen fark özelliği (Aşama 8)

### c. Doğrulanmayanlar ve bilinen sorunlar
- Girişi gerçek tarayıcıda (CSRF koruması açıkken) henüz denemedim. Giriş akışı yalnızca otomatik testle ve CSRF'si kapalı bir betikle denendi.
- Render'da `AGENT_PASSWORD`, `DATABASE_URL` ve `RAILS_MASTER_KEY` ayarları, Render'ın ücretsiz planındaki kısıtlar ve `Dockerfile`'ın Render'da çalışıp çalışmadığı denenmedi.
- Ruby 4.0.7 ile Rails'in ürettiği `bin/kamal` çalışmıyor (`fiddle` yüklenemiyor). Deploy Render'da yapılacağı için Kamal kullanılmayacak, ama bu sorun düzeltilmedi.
- Geliştirme ortamı Windows'tur, deploy ortamı Linux konteynerdir. `Dockerfile` ve `bin/docker-entrypoint` Linux'ta henüz çalıştırılmadı. Yalnızca dosyaların satır sonlarının LF olduğu kontrol edildi.
- Harcama ve süre kaydı (Bölüm 3.c) henüz doldurulmadı.