# CHALLENGE LOG: TempoDesk'ten Kâhya'ya Pivot Hikâyesi

Bu belge, projenin 1. haftasındaki klasik bilet sisteminden 2. haftada otonom kurumsal harcama denetim platformu **Kâhya**'ya geçiş (Pivot) kararını, nedenlerini, harcanan zamanı ve somut kanıtlarını belgeler.

---

## 1. Başlangıç Noktası

* **Klonlanan Ürün:** Zendesk (Müşteri Destek ve Bilet Yönetim Platformu).
* **Eski Canlı URL:** [https://tempodesk.onrender.com/](https://tempodesk.onrender.com/)
* **1. Hafta Son Commit Linki:** [Commit 3e5b010 - Readme updated](https://github.com/mustafa-karakoyun/TempoDesk/commit/3e5b010)
* **Kimin Neden Para Ödediği:**  
  Büyük ölçekli firmalar (ör. Uber Technologies, Siemens), yüzlerce temsilcinin müşteri şikayetlerini kuyrukta eritmesi, SLA sürelerinin aşılmaması ve e-posta kaosunun önlenmesi için kullanıcı/temsilci başına aylık lisans bedeli ödemektedir.

---

## 2. Acı (The Problem & Friction)

### İlk Projenin Hantallığı ("Form Slop"):
1. haftada geliştirilen bilet sistemi; müşterinin uzun bir form doldurduğu, temsilcinin bu formu okuyup manuel yanıt yazdığı ve yapay zekanın sadece özetleme veya otomatik taslak üretme gibi düşük değerli işler yaptığı hantal bir yapıydı. İnsan-insan form döngüsüne yapay zeka eklemek gerçek bir verimlilik sıçraması yaratmıyordu ("AI Slop").

### Harcama Denetiminde Kurumsal Acı (G2 & Capterra Doğrulaması):
Modern şirketlerde çalışanların ve otonom yazılım botlarının (DevOps botları, seyahat asistanları) kurumsal kartlarla yaptığı harcamalarda yaşanan gerçek sancı:
* **Fiş Kaçakları ve Kural İhlalleri:** Politika dışı harcamalar (iş yemeğinde alkol tüketimi, izinsiz donanım alımları) ancak ay sonunda muhasebe fişleri incelerken fark ediliyor. Para çoktan kasadan çıkmış oluyor.
* **Onay Kuyruğu Tıkanıklığı:** Yöneticiler yüzlerce küçük harcama fişini okumaktan bıkıyor; 100 TL'lik kırtasiye ile 5.000 TL'lik yetkisiz sunucu faturası aynı hantal onay kuyruğunda bekliyor.
* **Kanıt & Referanslar:**  
  [G2 Expense Management Software Reviews](https://www.g2.com/categories/expense-management) ve [Capterra Expense Report Software User Pain Points](https://www.capterra.com/expense-report-software/) incelemelerinde finans yöneticilerinin en büyük şikayeti: *"Harcamaların geç fark edilmesi, onay süreçlerinin gecikmesi ve denetim izinin ispatlanamaması."*

---

## 3. Bu Haftanın Vaadi

> **"1. haftadaki bilet durum makinesini (state machine) ve SLA eskalasyon omurgasını aldık; insan-insan destek formundan, Fortune 500 ölçeğinde otonom harcama denetleyicisi Kâhya'ya pivot ettik."**

Yeni sistemin taahhüdü:
1. Harcamayı bir yapay zeka ajanı bile API'den fırlatabilir.
2. Gemini LLM 10 maddelik şirket politikasını denetler; 1.000 TL altı temiz harcamaları **otomatik onaylar**.
3. Sadece gri alandaki şüpheli harcamalar gerekçesi ve risk skoruyla yöneticinin önüne düşer.
4. 24 saat içinde karar verilmeyen harcamalar otomatik olarak CFO onayına eskale olur.
5. Her hareket silinmez bir kriptografik denetim kaydına yazılır.

---

## 4. Yapılanlar ve Kanıt

### A. Git Commit Kanıtları
* [ba44a0e](https://github.com/mustafa-karakoyun/TempoDesk/commit/ba44a0e) — **Faz 1:** Çekirdek modeller (`Expense`, `ExpenseEvent`, `ExpensePolicy`), hesaplanan eskalasyon mantığı, seed verisi ve Kâhya marka dönüşümü.
* [6c5a7cd](https://github.com/mustafa-karakoyun/TempoDesk/commit/6c5a7cd) — **Faz 2:** Agent API (`POST /api/expenses`), Bearer auth, `LlmReviewer`, `ExpenseIntake`, eval seti ve demo agent betiği.
* [3e5ab0b](https://github.com/mustafa-karakoyun/TempoDesk/commit/3e5ab0b) — **Faz 3:** Yönetici & CFO harcama kartları, tek tık karar aksiyonu, denetim izi zaman çizelgesi ve eskalasyon testleri.
* [dfe608e](https://github.com/mustafa-karakoyun/TempoDesk/commit/dfe608e) — **Canlı Test:** Canlı harcama girişi ve anlık denetim formu.
* [0da681d](https://github.com/mustafa-karakoyun/TempoDesk/commit/0da681d) — **Stitch Tasarımı:** Pure Vanilla CSS ve HTML ile Stitch tasarım sisteminin birebir entegrasyonu.

### B. Otomasyon Test Kanıtı
```bash
$ ruby bin/rails test
Running 87 tests in a single process
Finished in 3.31s, 26.24 runs/s, 117.31 assertions/s.
87 runs, 389 assertions, 0 failures, 0 errors, 0 skips
```
* **24 Saatlik Zaman Kuralı Testi:** `test/controllers/manager/expenses_controller_test.rb:106` içinde `travel_to` kullanılarak zaman 24 saat 1 dakika ileri sarılmış; yöneticinin bakmadığı kartın otomatik CFO ekranına düştüğü doğrulanmıştır.

### C. Bilimsel Değerlendirme (LLM Eval Seti)
* 14 farklı uç sentetik vaka (alkol, yetkisiz donanım, kişisel alışveriş vb.) canlı Gemini 2.5 Flash API'ye sokuldu.
* **14 vakada 12 isabet — %85.7 Başarı Oranı**.
* Tüm çıktı ve gerekçeler [docs/EVAL_RESULTS.md](docs/EVAL_RESULTS.md) dosyasında kaydedildi.

### D. Açıkça Vaat Edilip Yetişmeyenler:
* Gerçek SAP / NetSuite ERP senkronizasyonu (API/mock seviyesinde bırakıldı).
* Canlı banka kartı provizyon API'si (test moduyla sınırlandırıldı).

---

## 5. Harcanan Zaman

* **İnsan Zamanı:** ~3 saat (Gereksinim analizi, kurumsal politika maddelerinin yazımı, prompt optimizasyonu, eval seti vakalarının tasarımı ve doğrulama).
* **Agent Zamanı:** ~1 saat (Tüm Ruby/Rails kodları, test suiteleri, Stitch saf Vanilla CSS entegrasyonu ve dokümantasyon).
* **Ajana Verilen İlk Prompt:**
  > *"Mevcut TempoDesk Rails uygulamasına harcama denetimi modülü ekliyoruz ve ürünün görünen adını Kâhya yapıyoruz. Yeni repo yok, yeni Render servisi yok: aynı repo, aynı CI, aynı deploy. Aort dilimi: Bir agent (ya da webhook) API'den harcama gönderir -> LLM şirket politikasına göre denetler -> temiz harcama otomatik onaylanır, gri alandaki harcama gerekçesiyle yöneticiye düşer -> yönetici tek tıkla onaylar/reddeder -> 24 saat cevapsız kalırsa CFO'ya eskale olur. Her adım denetim kaydına yazılır..."*

---

## 6. Karar: PIVOT (Eksen Değiştirme)

### Karar Gerekçesi:
1. **İnsan-İnsan Form Hantallığından Kurtulma:** Klasik destek biletleri artık günümüz yapay zekâ ajanı dünyasında "AI Slop" seviyesinde kalmaktadır.
2. **Mimari Sermayeyi Koruma:** 1. haftada inşa ettiğimiz SLA eskalasyonu, rol yetkilendirmesi ve durum makinesi (state machine) omurgasını atmadık; bunu doğrudan kurumsal harcama denetimine uyarlayarak yüksek katma değerli bir finansal bekçiye dönüştürdük.
3. **Agent-First Dünya:** Geleceğin şirketlerinde harcamaları insanlar değil yazılım ajanları yapacak. Kâhya, bu yeni dünyanın harcama onay kapısı (expense gatekeeper) olarak konumlanmıştır.
