# Kâhya — Yapay Zekâ Destekli Kurumsal Harcama Denetim Platformu

[![CI](https://github.com/mustafa-karakoyun/TempoDesk/actions/workflows/ci.yml/badge.svg)](https://github.com/mustafa-karakoyun/TempoDesk/actions/workflows/ci.yml)
![Ruby](https://img.shields.io/badge/Ruby-4.0.7-red)
![Rails](https://img.shields.io/badge/Rails-8.1.4-red)
![Tests](https://img.shields.io/badge/Tests-87%20passed-brightgreen)
![Eval Accuracy](https://img.shields.io/badge/LLM%20Eval-85.7%25-blue)
![License](https://img.shields.io/badge/License-MIT-blue)

> **Canlı Uygulama (Render):** [https://tempodesk.onrender.com/](https://tempodesk.onrender.com/)  
> **GitHub Deposu:** [https://github.com/mustafa-karakoyun/TempoDesk](https://github.com/mustafa-karakoyun/TempoDesk)  
> **Teknoloji Yığını:** Ruby 4.0.7, Ruby on Rails 8.1.4, PostgreSQL, Google Gemini 2.5 Flash LLM, Pure Vanilla CSS (Stitch UI Design System).

---

## 1. Ürün Tanımı ve İlham Kaynağı

**Kâhya**, kurumsal şirketlerde çalışanların ve otonom yazılım ajanlarının (DevOps botları, seyahat rezervasyon asistanları, satınalma entegrasyonları) yaptığı harcamaları anlık olarak denetleyen, şirket politikasına aykırı fişleri tespit edip yöneticinin önüne gerekçesiyle getiren **Yapay Zekâ Destekli Kurumsal Harcama Denetim Platformudur**.

> **İlham Kaynağı:**  
> *Bu ürün Ramp ve Brex modellerinden ilham alınarak geliştirilmiştir.*  
> Uygulama arayüzünde hiçbir orijinal rakip marka/logo yer almaz; tamamen bağımsız ve kurumsal "Kâhya" kimliğiyle çalışır.

---

## 2. Faz 1: Küçük Araştırma (Kaynaklı Rakamlar)

Kurumsal ölçekte (Fortune 500 ve hızlı büyüyen teknoloji şirketleri) finansal harcama hacmi ve harcama yönetimi araçlarının gerekliliği şu verilerle doğrulanmıştır:

| Metrik | Değer / Aralık | Kaynak Linki (Açık Erişim) |
| :--- | :--- | :--- |
| **Fortune 500 Değerleme Aralığı** | $10 Milyar — $5 Trilyon+ | [Fortune 500 Resmi Listesi](https://fortune.com/ranking/fortune500/) & [Statista Market Cap](https://www.statista.com/) |
| **Çalışan Sayısı Aralığı** | 1.000 — 1.500.000+ çalışan | [Fortune 500 Şirket Verileri](https://fortune.com/ranking/fortune500/) |
| **Firma Başı SaaS Sayısı** | Ortalama **100+ ile 320+ adet SaaS** | [BetterCloud State of SaaSOps Report](https://www.bettercloud.com/saasops-resources/state-of-saasops-report/) |
| **Yıllık SaaS / Finansal Harcama** | Firma başı yıllık **~$50M – $100M+** | [Zylo SaaS Spend Management Index](https://zylo.com/blog/saas-spend-management) |
| **Küresel Medya & Kurumsal Kanıt** | **Fortune Media** (Fortune 500 yayıncısı) | [PR Newswire: Fortune Media Selects Ramp to Modernize Financial Operations](https://www.prnewswire.com/news-releases/fortune-media-selects-ramp-to-modernize-financial-operations-302880062.html) |
| **Kurumsal Harcama Müşteri Örneği** | **Shopify** (10.000+ çalışan) | [Ramp Müşteri Vaka Analizi: Shopify](https://ramp.com/customers/shopify) |
| **Büyüme Ölçeği Müşteri Örneği** | **Webflow** (Harcama denetimi) | [Ramp Müşteri Vaka Analizi: Webflow](https://ramp.com/customers/webflow) |

---

## 3. Faz 2: Maliyet ve Efor Tahmini

Kurumsal harcama denetimi ve kart yönetim platformlarının (Ramp / Brex çekirdeği) sıfırdan geliştirilmesi için yapılan analitik tahmin:

* **Yaklaşık Kod Boyutu:** ~300.000 satır (LOC) backend/frontend/altyapı kodu.  
  *Tahmin Yöntemi:* Fatura ayrıştırma, rol bazlı onay mekanizmaları, çoklu onay zincirleri, muhasebe entegrasyonu (ERP sync), limit yönetimi ve denetim kayıtları modüllerinin sektör standartlarındaki fonksiyonel puan (Function Point Analysis - COCOMO II) metoduyla hesaplanması.
* **Coding Agent'lar ile Çekirdek Geliştirme Maliyeti:**
  * **LLM API & Token Maliyeti:** ~$100 — $150 (Claude 3.7 Sonnet / Gemini 2.5 Flash token tüketimi ve abonelik maliyeti).
  * **Süre:** 3 — 5 iş günü.
* **Bu Projede Harcanan Gerçek Efor:**
  * **İnsan Eforu:** ~3 saat (Gereksinim belirleme, kurumsal politika maddelerinin yazımı, prompt optimizasyonu, eval seti vakalarının tasarımı ve doğrulama).
  * **Agent Eforu:** ~1 saat (Tüm Rails modelleri, SLA eskalasyon hesaplamaları, Gemini API istemcisi, Stitch UI Vanilla CSS tasarımı ve 87 otomasyon testinin yazılması).

---

## 4. Aort Dilimi ve Sistem Mimarisi

Kâhya, "form doldurma slop'u" yerine doğrudan **Agent-First ve Human-in-the-Loop (HITL)** mimarisine odaklanır:

```
[Dış Sistem / Ajan / Webhook]
             │
             │  1. POST /api/expenses (Bearer Token Yetkilendirmesi)
             ▼
[Kâhya Denetim Motoru (ExpenseIntake)]
             │
             │  2. Gemini 2.5 Flash (Sistem 1: Yapılandırılmış JSON & 10 Kural)
             ▼
    ┌───────────────────────────┴───────────────────────────┐
    │                                                       │
[Temiz & <= 1.000 TL]                              [Şüpheli veya > 1.000 TL]
    │                                                       │
    ▼                                                       ▼
OTOMATİK ONAY                                     YÖNETİCİ KOKPİTİNE SEVK
(İnsan görmez, süreç tıkanmaz)                    (Gerekçe + Risk Puanı: %0-100)
                                                            │
                                                            ├──> Yönetici Tek Tıkla Onaylar/Reddeder
                                                            │
                                                            └──> 24 Saat İçinde Bakılmazsa:
                                                                 CFO MASASINA ESKALE OLUR
                                                                 (travel_to ile test edilmiştir)
                                                            │
                                                            ▼
                                              KRİPTOGRAFİK DENETİM İZİ
                                              (Değiştirilemez ExpenseEvents)
```

### Çekirdek Tasarım Kuralları:
1. **Politika Tek Yerde Yaşar:** Tutar eşikleri (1.000 TL otomatik onay tavanı, 5.000 TL CFO tavanı) ve 24 saatlik eskalasyon süresi yalnızca `app/models/expense_policy.rb` içindedir; kodda dağınık sabit bulunmaz.
2. **Eskalasyon Hesaplanır, Saklanmaz:** `escalated` veritabanı sütunu veya cron yoktur. `Expense#escalated?` metodu `Time.current > review_due_at` üzerinden anlık hesaplanır.
3. **Fail-Closed Güvencesi:** Gemini API zaman aşımına uğrar veya hata verirse harcama asla otomatik onaylanmaz; `pending_review` statüsünde bekletilerek insana sevk edilir.
4. **Stitch UI (Saf Vanilla CSS):** Arayüzde hiçbir harici framework veya Tailwind kullanılmamış; Stitch MCP tasarım sisteminden türetilen %100 saf Vanilla CSS ve modern Inter / JetBrains Mono fontlarıyla inşa edilmiştir.

---

## 5. Test ve Doğrulama

Uygulamadaki her özellik kanıtlanabilir testlerle doğrulanmıştır:

### Otomasyon Test Paketi (Minitest)
```bash
$ ruby bin/rails test
Finished in 3.31s, 26.24 runs/s, 117.31 assertions/s.
87 runs, 389 assertions, 0 failures, 0 errors, 0 skips
```
* **Kapsam:** Rol matrisi (Agent, Manager, CFO), API Bearer yetkilendirmesi, fail-closed LLM davranışı, tek tık karar aksiyonları, mükerrer karar engelleme, `travel_to` ile 24 saat 1 dakika sonra CFO'ya otomatik eskalasyon ve denetim izi zaman çizelgesi.

### Bilimsel Değerlendirme Seti (LLM Eval)
Yapay zekanın doğruluğunu ölçmek için 14 sentetik uç vakadan oluşan eval seti (`test/fixtures/files/llm_eval_cases.yml`) canlı Gemini 2.5 Flash API ile test edilmiştir:
* **Sonuç:** **14 vakada 12 doğru karar — %85.7 Başarı Oranı**.
* **Detaylı Rapor:** [docs/EVAL_RESULTS.md](docs/EVAL_RESULTS.md) dosyasında her vakanın prompt çıktısı ve Gemini'ın verdiği gerekçeler şeffafça belgelenmiştir.

---

## 6. Canlı Demo ve Test Senaryosu

### A. Web Arayüzünden Canlı Harcama Girme (HITL Testi):
1. `https://tempodesk.onrender.com/` adresine gidin ve Yönetici olarak giriş yapın (`manager@kahya.example` / `password123`).
2. Sağ üstteki **`+ Canlı Harcama Gir (Test Et)`** butonuna basın.
3. Bir harcama gönderin:
   - **İhlal Denemesi:** Tutar: `1.500 TL`, Açıklama: *"Müşteri yemeğinde 2 kadeh şarap"*.  
     *Sonuç:* Gemini harcamayı **Madde 4 (Alkol İhlali)** gerekçesiyle incelemeye alır ve risk puanıyla yönetici masasına düşürür.
   - **Temiz Harcama Denemesi:** Tutar: `350 TL`, Açıklama: *"Ofis için tahta kalemi"*.  
     *Sonuç:* Gemini harcamayı **Madde 1 (Ofis Limiti Uyumu)** ile anında otomatik onaylar.

### B. Otonom Ajan API Testi (Terminal):
```powershell
# PowerShell üzerinden hazır demo ajanını çalıştırma:
./docs/demo_agent.ps1
```

---

## 7. Yapamadıklarım (Dürüst Eksikler Listesi)

Ödev süresi ve kapsam sınırları doğrultusunda şu özellikler bilinçli olarak kapsam dışı bırakılmıştır:
1. **Gerçek Kurumsal ERP (SAP / NetSuite) Entegrasyonu:** Gerçek bir ERP sistemiyle canlı iki yönlü senkronizasyon kurulmamış; webhook ve API seviyesinde mock entegrasyonla sınırlandırılmıştır.
2. **Canlı Banka / Kart Provizyonu:** Gerçek banka sanal kart API'si yerine sentetik kurumsal kart modelleri kullanılmıştır.
3. **OCR (Görsel Fiş Okuma):** Fiş görseli yükleme ve OCR ayrıştırma kapsam dışı bırakılmış, harcama açıklaması ve JSON metin yükü üzerinden denetim yapılmıştır.
4. **E-posta / SMS Bildirimleri:** Eskalasyon durumunda harici e-posta gönderimi eklenmemiş; denetim paneli ve arayüz içi sayaçlar kullanılmıştır.

---

## 8. Kurulum ve Ortam Değişkenleri

```bash
# Bağımlılıkları yükle
bundle install

# Veritabanını hazırla ve seed verilerini yükle
bin/rails db:prepare
bin/rails db:seed

# Testleri çalıştır
bin/rails test

# Sunucuyu başlat
bin/rails server
```

### Gerekli Ortam Değişkenleri (`.env`):
* `GEMINI_API_KEY`: Google AI Studio API anahtarı
* `GEMINI_MODEL`: `gemini-2.5-flash`
* `AGENT_API_KEY`: Dış ajanların API erişimi için Bearer token (örn: `kahya-secret-agent-key-2026`)