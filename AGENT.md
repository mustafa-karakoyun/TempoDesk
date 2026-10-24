# AGENT.md: Kâhya

Bu dosya, bu repoda çalışan coding agent'ın uyacağı kuralları anlatır. Görev ayrıntıları `KAHYA_PLAN.md` içindedir. Bu dosya kısa tutulur ve her oturumda baştan okunur.

## Proje
Kâhya (eski adı TempoDesk), AI agent'ların API'den gönderdiği şirket harcamalarını politikaya göre denetleyen bir üründür: LLM denetler, temiz harcama otomatik onaylanır, gri alandaki harcama gerekçesiyle yöneticiye düşer, 24 saat cevapsız kalırsa CFO'ya eskale olur, her adım denetim kaydına yazılır. Repoda ayrıca ilk haftadan kalan destek bileti modülü (müşteri bilet açar, temsilci yanıtlar, SLA izlenir) çalışır durumdadır ve bozulmamalıdır. Ruby on Rails 8+, PostgreSQL, Minitest. Canlıda Render'da çalışır. Ders ödevidir, puanlama 0 / 85 / 100'dür.

## Çalışma şekli
1. Her oturumda `KAHYA_PLAN.md`'yi oku. Yalnızca insanın istediği fazı yap, bitince dur ve rapor ver. Kendiliğinden sonraki faza geçme.
2. Emin olmadığın şeyi (gem sürümü, Render ayarı, Gemini API biçimi, model adı) tahmin etme. "Bilmiyorum, kontrol edilmeli" yaz ve resmi dokümana bak ya da sor.
3. Kapsamı büyütme. Planın "kapsam dışı" listesindeki hiçbir şeyi ekleme.
4. Küçük commit'ler at, her commit mesajı ne değiştiğini söylesin. Faz bitmeden commit atma, testler yeşil olmalı.

## Doğrulama (en önemli kural)
- Bir şeyin çalıştığını yalnızca **gerçekten çalıştırıp çıktıyı görerek** söyle.
- Test çıktısının son satırlarını (çalışma sayısı, hata, başarısızlık) rapora olduğu gibi yapıştır. Özet yazma, çıktıyı yapıştır.
- Çalıştıramadığını "çalıştırılmadı" diye yaz. "Çalışması gerekir" bir sonuç değildir.
- Test başarısız olursa testi değiştirerek geçirme. Önce kodun mu testin mi yanlış olduğunu açıkla.
- Yeni davranışı tarayıcıdan, `curl` ile veya `ruby bin/rails runner` ile dene ve ne gördüğünü yaz.
- LLM değerlendirme sonuçlarını (`rake eval:llm`) asla elle düzeltme veya uydurma. Çalıştıramadıysan "çalıştırılmadı" yaz.

## Komutlar (Windows, PowerShell)
```
ruby bin/rails test                  # tüm testler
ruby bin/rails test test/models      # model testleri
ruby bin/rails db:create db:migrate  # veritabanı
ruby bin/rails db:seed               # demo verisi (idempotent olmalı)
ruby bin/rails server                # sunucu, /up yeşil dönmeli
ruby bin/rails eval:llm              # gerçek Gemini ile değerlendirme (GEMINI_API_KEY gerekir)
```

## Ortam değişkenleri (hiçbiri koda veya commit'e yazılmaz)
`PGPASSWORD` (veritabanı), `AGENT_PASSWORD`, `MANAGER_PASSWORD`, `CFO_PASSWORD` (seed hesapları), `AGENT_API_KEY` (API Bearer anahtarı), `GEMINI_API_KEY`, `GEMINI_MODEL`. Hiçbirini dosyaya, çıktıya veya commit'e yazma. Production'da `AGENT_API_KEY` yoksa API 401 döner, uygulama çökmez ve açık kalmaz.

## Marka kuralı
Ürün adı Kâhya (arayüzde "Kâhya", kodda ve dosya adlarında ASCII `kahya`). Eski ad TempoDesk yalnızca README, CHALLENGE_LOG, repo/URL adı ve eski seed e-postasının taşınması için geçebilir; arayüzde, `<title>`'da, logoda ve yeni dosyalarda geçmez. İlham kaynağı ürünlerin adları (aşağıdaki desen) README ve plan/log dosyaları dışında **hiçbir yerde** geçmez: kod, görünüm, `<title>`, favicon, seed, yorum satırı, dosya adı. Her faz sonunda şunu çalıştır, sonuç boş olmalı:
```
Get-ChildItem -Recurse -File -Exclude README.md,AGENT.md,KAHYA_PLAN.md,TEMPODESK_PLAN.md,CHALLENGE_LOG.md | Select-String -Pattern "\b(zendesk|ramp|brex)\b" -List | Where-Object { $_.Path -notmatch "\\\.git\\|node_modules|\\log\\|\\tmp\\|\\vendor\\|\\docs\\" }
```

## Kod kuralları: harcama modülü
- **Politika tek yerde:** Tutar eşikleri, onaycı rolü ve eskalasyon süresi yalnızca `app/models/expense_policy.rb` içinde yaşar. Başka dosyada `24.hours` veya tutar sabiti yazma.
- **Eskalasyon hesaplanır:** `escalated` sütunu, zamanlayıcı iş, cron yok. `Expense#escalated?` bir metottur.
- **Durum geçişi:** `Expense#transition_to!(status, actor:, reason:)` kullanılır, izinsiz geçiş `InvalidTransition` fırlatır. Durumu doğrudan `update(status: ...)` ile değiştirme. Her geçiş `expense_events` kaydı yazar.
- **LLM sert kuralı aşamaz:** LLM `approve` dese bile `ExpensePolicy.auto_approvable?` false ise harcama insana düşer. LLM otomatik reddetmez, yalnızca `approve` veya `flag` döner.
- **Fail-closed:** LLM hatası, zaman aşımı veya bozuk şema (1 yeniden deneme sonrası) durumunda harcama `pending_review` kalır. Hata durumunda otomatik onay yok.
- **Anahtar kelimeyle karar yok:** `description.include?("acil")` gibi kontroller yasak. Yargı LLM'in, kesin kurallar `ExpensePolicy`'nin.
- **LLM çağrısı:** `LlmReviewer` arkasında, `Net::HTTP` ile, 8-10 sn timeout. Testlerde sahte istemci verilir, gerçek ağ çağrısı yok.
- **API girişi:** `POST /api/expenses`, Bearer anahtarı `ActiveSupport::SecurityUtils.secure_compare` ile doğrulanır.
- **Sentetik veri:** Seed ve testlerde gerçek kişisel veya kart bilgisi yok.

## Kod kuralları: genel ve bilet modülü
- **Enum:** Tüm enum'larda `prefix: true` zorunlu (`new` değeri `Ticket.new` ile çakışır).
- **SLA tek yerde:** Bilet süre kuralı yalnızca `app/models/sla_policy.rb` içinde yaşar. İhlal `Ticket#sla_breached?` ile hesaplanır, sütun yok. Bilet durumu `Ticket#transition_to!` ile değişir.
- **Zaman testleri:** Zamanı yalnızca testlerde `travel_to` ile değiştir. Canlı uygulamada zamanı değiştiren arayüz veya gizli rota yok. Seed'de `travel_to` kullanma.
- **Seed:** `find_or_create_by!` ile idempotent. Süresi geçmiş kayıtlar için `created_at` ve ilgili süre alanı açıkça verilir.
- **Kimlik doğrulama:** Rails 8 yerleşik üreteci. Herkese açık controller'lar `allow_unauthenticated_access` kullanır. Roller: `agent`, `manager`, `cfo`.
- Sade ERB ve vanilla CSS, JavaScript sayaç yok. Gereksiz gem ekleme, eklemeden önce sor. Harici CSS framework ekleme.

## Yasaklar
- Ödeme veya kart bilgisi akışı
- Kapsam dışı özellikler (e-posta/Telegram bildirimi, otomatik reddetme, çoklu para birimi, RAG vb.)
- Gizli bilgiyi (şifre, API anahtarı, `master.key`, `.env`) commit etmek veya çıktıya yazmak
- Test çalıştırmadan "geçti" demek
- Rapor veya değerlendirme sonucu uydurmak. Yapılamayanı yapılamadı diye yaz.

## Rapor biçimi
Her faz sonunda: (1) yapılanlar, (2) çalıştırılan komutlar ve gerçek çıktıları, (3) yapılamayanlar ve nedenleri, (4) insanın yapması gerekenler.
