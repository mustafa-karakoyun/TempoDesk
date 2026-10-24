# Kâhya — LLM Denetim Değerlendirme Sonuçları

- **Tarih:** 24.10.2026 20:44
- **Model:** `gemini-2.5-flash`
- **Toplam Vaka:** 14
- **Doğru Eşleşme:** 12/14
- **Başarı Oranı:** %85.7

---

## Vaka Karşılaştırma Tablosu

| ID | Satıcı | Tutar | Açıklama | Beklenen | Gerçek | Durum | Risk | Politika Maddesi |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `case_1` | Ofis Kırtasiye Ltd. | 450.00 ₺ | Temsilci ekibi için 5 top A4 fotokopi kağıdı ve tükenmez kalem alımı | `approve` | `approve` | ✓ Uyumlu | 5 | Madde 1 |
| `case_2` | Steam Valve Corp | 1200.00 ₺ | Cuma akşamı ekip için Steam oyun mağazasından çok oyunculu oyun lisansları | `flag` | `flag` | ✓ Uyumlu | 95 | Madde 8 |
| `case_3` | GitHub Inc. | 850.00 ₺ | Aylık GitHub Enterprise ve CI/CD ek işlemci dakikası aboneliği | `approve` | `approve` | ✓ Uyumlu | 10 | Madde 3 |
| `case_4` | Boğaz Lounge & Club | 3800.00 ₺ | Pazar gecesi lüks eğlence kulübünde VIP masa ve içki harcaması | `flag` | `flag` | ✓ Uyumlu | 95 | Madde 4, Madde 8, Madde 9 |
| `case_5` | D&R Kitap Mağazası | 650.00 ₺ | Yazılım ekibi için 'Designing Data-Intensive Applications' teknik referans kitabı | `approve` | `approve` | ✓ Uyumlu | 0 | Madde 7 |
| `case_6` | Apple Store Zorlu Center | 9500.00 ₺ | Yeni mühendis için 16 inç Apple MacBook Pro M4 iş istasyonu alımı | `flag` | `flag` | ✓ Uyumlu | 50 | Madde 2 |
| `case_7` | Teknosa Mağazacılık | 750.00 ₺ | Ofis toplantı odası için ergonomik kablosuz klavye ve fare | `approve` | `approve` | ✓ Uyumlu | 0 | Madde 1 |
| `case_8` | Opet Akaryakıt İstasyonu | 1800.00 ₺ | Şirket arabası olmayan çalışan için hafta sonu özel şahsi benzin harcaması | `flag` | `flag` | ✓ Uyumlu | 95 | Madde 5 |
| `case_9` | Amazon Web Services | 4200.00 ₺ | Yıllık AWS GPU sunucu rezervasyon taahhüt ücreti | `flag` | `approve` | ✗ Farklı | 10 | Madde 3 |
| `case_10` | Migros Sanal Market | 550.00 ₺ | Ofis mutfağı için çay, filtre kahve ve su siparişi | `approve` | `approve` | ✓ Uyumlu | 5 | Madde 1 |
| `case_11` | Çeşitli Ticaret Ltd. | 900.00 ₺ | Genel departman harcaması ve muhtelif giderler | `flag` | `flag` | ✓ Uyumlu | 65 | Madde 10 |
| `case_12` | Köşebaşı Kebap | 950.00 ₺ | İş ortağı teknoloji direktörü ile öğle yemeği iş toplantısı | `approve` | `approve` | ✓ Uyumlu | 15 | Madde 4, Madde 10 |
| `case_13` | Vatan Bilgisayar | 2900.00 ₺ | Çalışanın evine PlayStation 5 oyun konsolu ve kumanda alımı | `flag` | `flag` | ✓ Uyumlu | 95 | Madde 8 |
| `case_14` | Figma Inc. | 720.00 ₺ | Figma Professional tasarım ekibi aylık lisans bedeli | `approve` | `flag` | ✗ Farklı | - | - |

---

## Detaylı Gerekçeler

### case_1: Ofis Kırtasiye Ltd. (450.00 ₺)
- **Açıklama:** Temsilci ekibi için 5 top A4 fotokopi kağıdı ve tükenmez kalem alımı
- **Kural Notu:** Madde 1: 1.000 TL altı ofis sarf malzemesi
- **Beklenen / Gerçek:** `approve` / `approve` (Uyumlu)
- **Risk Skoru:** 5
- **Politika Maddesi:** Madde 1
- **LLM Gerekçesi:** Harcama, temsilci ekibi için yapılan 450 TL tutarındaki ofis sarf ve kırtasiye malzemesi alımıdır. Politikanın 'Madde 1'ine göre, ofis sarf ve kırtasiye malzemeleri 1.000 TL altında ve departman operasyon ihtiyaçları doğrultusunda doğrudan onaylanabilir. Açıklama net ve doğrulayıcıdır, bu da 'Madde 10' ile uyumludur.

### case_2: Steam Valve Corp (1200.00 ₺)
- **Açıklama:** Cuma akşamı ekip için Steam oyun mağazasından çok oyunculu oyun lisansları
- **Kural Notu:** Madde 8: Kişisel eğlence ve oyun yazılımı alımı yasak
- **Beklenen / Gerçek:** `flag` / `flag` (Uyumlu)
- **Risk Skoru:** 95
- **Politika Maddesi:** Madde 8
- **LLM Gerekçesi:** Harcama, şirket bütçesiyle Steam üzerinden çok oyunculu oyun lisansları alımı olup, politika Madde 8'de 'kişisel eğlence, oyun (Steam, konsol oyunları vb.)' alımının kesinlikle yasak olduğu ve incelemeye sevk edileceği belirtilmiştir. Bu durum açık bir politika ihlalidir.

### case_3: GitHub Inc. (850.00 ₺)
- **Açıklama:** Aylık GitHub Enterprise ve CI/CD ek işlemci dakikası aboneliği
- **Kural Notu:** Madde 3: İş amaçlı onaylı SaaS lisansı ve 1.000 TL altı
- **Beklenen / Gerçek:** `approve` / `approve` (Uyumlu)
- **Risk Skoru:** 10
- **Politika Maddesi:** Madde 3
- **LLM Gerekçesi:** Harcama tutarı otomatik onay limitinin (1.000 TL) altındadır. Harcama kategorisi (Yazılım/SaaS) ve satıcı (GitHub Inc.) Madde 3'te belirtilen iş amaçlı bulut altyapısı, SaaS lisansları ve geliştirici araçları tanımına uymaktadır. Açıklama net ve işlevselliği (GitHub Enterprise ve CI/CD aboneliği) doğrulamaktadır.

### case_4: Boğaz Lounge & Club (3800.00 ₺)
- **Açıklama:** Pazar gecesi lüks eğlence kulübünde VIP masa ve içki harcaması
- **Kural Notu:** Madde 4, 8 ve 9: Hafta sonu alkol/eğlence ağırlıklı şüpheli harcama
- **Beklenen / Gerçek:** `flag` / `flag` (Uyumlu)
- **Risk Skoru:** 95
- **Politika Maddesi:** Madde 4, Madde 8, Madde 9
- **LLM Gerekçesi:** Harcama, Pazar günü lüks bir eğlence kulübünde yapılan VIP masa ve içki gideridir. Bu durum, Madde 4'te belirtilen lüks tüketim ve alkol ağırlıklı harcamaların incelemeye alınması, Madde 8'deki kişisel eğlence ve yasaklı harcamalar yasağı ile Madde 9'daki hafta sonu temsil harcamalarının olağan dışı risk taşıması hükümlerini açıkça ihlal etmektedir. Harcamanın iş amaçlı olduğuna dair bir açıklama bulunmamaktadır.

### case_5: D&R Kitap Mağazası (650.00 ₺)
- **Açıklama:** Yazılım ekibi için 'Designing Data-Intensive Applications' teknik referans kitabı
- **Kural Notu:** Madde 7: Mesleki gelişim kitabı ve 1.000 TL altı
- **Beklenen / Gerçek:** `approve` / `approve` (Uyumlu)
- **Risk Skoru:** 0
- **Politika Maddesi:** Madde 7
- **LLM Gerekçesi:** Harcama, 1.000 TL otomatik onay limitinin altındadır ve yazılım ekibi için alınan 'Designing Data-Intensive Applications' teknik referans kitabı, Madde 7'de belirtilen çalışanın doğrudan iş alanıyla ilgili mesleki eğitim ve teknik yayın harcamaları kriterine tamamen uymaktadır. Açıklama net ve doğrulayıcıdır.

### case_6: Apple Store Zorlu Center (9500.00 ₺)
- **Açıklama:** Yeni mühendis için 16 inç Apple MacBook Pro M4 iş istasyonu alımı
- **Kural Notu:** Madde 2: 5.000 TL üzeri harcama CFO incelemesine tabidir
- **Beklenen / Gerçek:** `flag` / `flag` (Uyumlu)
- **Risk Skoru:** 50
- **Politika Maddesi:** Madde 2
- **LLM Gerekçesi:** Harcama tutarı (9500.00 TL), politika madde 2'de belirtilen 5.000 TL üzerindeki CFO inceleme eşiğini aşmaktadır ve bu nedenle doğrudan CFO onayına yönlendirilmelidir. Ayrıca, politika madde 6'ya göre donanım alımlarının IT departmanı onaylı standart envanter listesinde olup olmadığı doğrulanmalıdır.

### case_7: Teknosa Mağazacılık (750.00 ₺)
- **Açıklama:** Ofis toplantı odası için ergonomik kablosuz klavye ve fare
- **Kural Notu:** Madde 1: 1.000 TL altı ofis ergonomi ekipmanı
- **Beklenen / Gerçek:** `approve` / `approve` (Uyumlu)
- **Risk Skoru:** 0
- **Politika Maddesi:** Madde 1
- **LLM Gerekçesi:** Harcama, 750 TL tutarındaki ofis malzemeleri kategorisinde olup, 1.000 TL altındaki limit dahilindedir. Ofis toplantı odası için ergonomik klavye ve fare alımı, departman operasyonel ihtiyaçları doğrultusunda değerlendirilmektedir. Politikanın 1. maddesine uygun olarak doğrudan onaylanabilir bir harcamadır. Açıklama net ve harcama tarihi hafta içine denk gelmektedir.

### case_8: Opet Akaryakıt İstasyonu (1800.00 ₺)
- **Açıklama:** Şirket arabası olmayan çalışan için hafta sonu özel şahsi benzin harcaması
- **Kural Notu:** Madde 5 ve 9: Hafta sonu şahsi akaryakıt kullanımı
- **Beklenen / Gerçek:** `flag` / `flag` (Uyumlu)
- **Risk Skoru:** 95
- **Politika Maddesi:** Madde 5
- **LLM Gerekçesi:** Harcama açıklaması, şirket arabası olmayan bir çalışan için hafta sonu yapılan "özel şahsi benzin harcaması" olduğunu açıkça belirtmektedir. Bu durum, Madde 5'teki "özel araç şahsi yakıt kullanımı bayraklanır" hükmünü ve Madde 8'deki şirket bütçesiyle kişisel harcama yasağını doğrudan ihlal etmektedir.

### case_9: Amazon Web Services (4200.00 ₺)
- **Açıklama:** Yıllık AWS GPU sunucu rezervasyon taahhüt ücreti
- **Kural Notu:** Madde 6: Uzun dönemli rezervasyon ve taahhüt yönetici incelemesi gerektirir
- **Beklenen / Gerçek:** `flag` / `approve` (Farklı)
- **Risk Skoru:** 10
- **Politika Maddesi:** Madde 3
- **LLM Gerekçesi:** Harcama, politika maddesi 3'te belirtilen "Bulut altyapısı" kategorisine girmektedir ve satıcı Amazon Web Services açıkça belirtilmiştir. "Yıllık AWS GPU sunucu rezervasyon taahhüt ücreti" açıklaması, harcamanın iş amacına yönelik ve projelendirilmiş olduğunu net bir şekilde göstermektedir. Tutar, CFO inceleme eşiğinin altında olup, harcama tarihi hafta içi bir gündür.

### case_10: Migros Sanal Market (550.00 ₺)
- **Açıklama:** Ofis mutfağı için çay, filtre kahve ve su siparişi
- **Kural Notu:** Madde 1: Ofis sarf ihtiyacı ve 1.000 TL altı
- **Beklenen / Gerçek:** `approve` / `approve` (Uyumlu)
- **Risk Skoru:** 5
- **Politika Maddesi:** Madde 1
- **LLM Gerekçesi:** Harcama, ofis mutfağı için çay, filtre kahve ve su siparişi olup, 550 TL tutarındadır. Bu harcama, Politika Madde 1'de belirtilen 1.000 TL altındaki ofis sarf ve kırtasiye malzemeleri için doğrudan onay limitine ve departman operasyonel ihtiyaçlarına uygun düşmektedir. Harcama açıklaması açık ve doğrulanabilirdir. Hafta içi yapılmış olup, diğer maddelerle çelişmemektedir.

### case_11: Çeşitli Ticaret Ltd. (900.00 ₺)
- **Açıklama:** Genel departman harcaması ve muhtelif giderler
- **Kural Notu:** Madde 10: Muğlak ve gerekçelendirilmemiş açıklama
- **Beklenen / Gerçek:** `flag` / `flag` (Uyumlu)
- **Risk Skoru:** 65
- **Politika Maddesi:** Madde 10
- **LLM Gerekçesi:** Harcama açıklaması "Genel departman harcaması ve muhtelif giderler" ifadesini içermektedir. Politikanın 10. Maddesi, "muğlak ('muhtelif gider') açıklamaların incelemeye bayraklandığını" açıkça belirtmektedir. Tutar otomatik onay limiti altında olsa da, açıklamanın net olmaması nedeniyle harcamanın detaylı incelenmesi gerekmektedir.

### case_12: Köşebaşı Kebap (950.00 ₺)
- **Açıklama:** İş ortağı teknoloji direktörü ile öğle yemeği iş toplantısı
- **Kural Notu:** Madde 4: Hafta içi iş yemeği ve 1.000 TL altı makul tutar
- **Beklenen / Gerçek:** `approve` / `approve` (Uyumlu)
- **Risk Skoru:** 15
- **Politika Maddesi:** Madde 4, Madde 10
- **LLM Gerekçesi:** Harcama tutarı (950 TL), otomatik onay limiti olan 1.000 TL altındadır. Harcama açıklaması (İş ortağı teknoloji direktörü ile öğle yemeği iş toplantısı) Madde 4'e göre iş amaçlı temsil ve ağırlama kapsamına girmektedir. Hafta içi (Perşembe) yapıldığı için Madde 9 kısıtlaması yoktur ve Madde 10'daki açıklama gerekliliklerini karşılamaktadır. Düşük riskli ve politika uyumlu bir harcamadır.

### case_13: Vatan Bilgisayar (2900.00 ₺)
- **Açıklama:** Çalışanın evine PlayStation 5 oyun konsolu ve kumanda alımı
- **Kural Notu:** Madde 8: Şahsi oyun/eğlence cihazı şirket bütçesinden karşılanamaz
- **Beklenen / Gerçek:** `flag` / `flag` (Uyumlu)
- **Risk Skoru:** 95
- **Politika Maddesi:** Madde 8
- **LLM Gerekçesi:** Harcama, politika Madde 8'de belirtilen "kişisel eğlence, oyun (konsol oyunları vb.)" kategorisine girmektedir ve şirket bütçesiyle bu tür alımlar kesinlikle yasaktır. Çalışanın evine PlayStation 5 oyun konsolu alımı, şirket harcama politikasına açıkça aykırıdır.

### case_14: Figma Inc. (720.00 ₺)
- **Açıklama:** Figma Professional tasarım ekibi aylık lisans bedeli
- **Kural Notu:** Madde 3: İş amaçlı tasarım aracı ve 1.000 TL altı
- **Beklenen / Gerçek:** `approve` / `flag` (Farklı)
- **Risk Skoru:** 
- **Politika Maddesi:** 
- **LLM Gerekçesi:** LLM kullanılamadı

