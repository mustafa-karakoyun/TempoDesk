# AGENT.md: TempoDesk

Bu dosya, bu repoda çalışan coding agent'ın uyacağı kuralları anlatır. Görev ayrıntıları `TEMPODESK_PLAN.md` içindedir. Bu dosya kısa tutulur ve her oturumda baştan okunur.

## Proje
TempoDesk, bir destek bileti (helpdesk) ürününün aort dilimidir: müşteri bilet açar, temsilci yanıtlar, bilet çözülür, çözüm süresi önceliğe göre SLA'ya karşı izlenir. Ruby on Rails 8+, PostgreSQL, Minitest. Canlıda Render'da çalışır. Ders ödevidir, puanlama 0 / 85 / 100'dür.

## Çalışma şekli
1. Her oturumda `TEMPODESK_PLAN.md`'yi oku. Yalnızca insanın istediği aşamayı yap, bitince dur ve rapor ver. Kendiliğinden sonraki aşamaya geçme.
2. Emin olmadığın şeyi (gem sürümü, Render ayarı, Rails davranışı) tahmin etme. "Bilmiyorum, kontrol edilmeli" yaz ve sor.
3. Kapsamı büyütme. Planın "kapsam dışı" listesindeki hiçbir şeyi ekleme.
4. Küçük commit'ler at, her commit mesajı ne değiştiğini söylesin. Aşama bitmeden commit atma, testler yeşil olmalı.

## Doğrulama (en önemli kural)
- Bir şeyin çalıştığını yalnızca **gerçekten çalıştırıp çıktıyı görerek** söyle.
- Test çıktısının son satırlarını (çalışma sayısı, hata, başarısızlık) rapora olduğu gibi yapıştır. Özet yazma, çıktıyı yapıştır.
- Çalıştıramadığını "çalıştırılmadı" diye yaz. "Çalışması gerekir" bir sonuç değildir.
- Test başarısız olursa testi değiştirerek geçirme. Önce kodun mu testin mi yanlış olduğunu açıkla.
- Yeni davranışı tarayıcıdan veya `ruby bin/rails runner` ile dene ve ne gördüğünü yaz.

## Komutlar (Windows, PowerShell)
```
ruby bin/rails test                  # tüm testler
ruby bin/rails test test/models      # model testleri
ruby bin/rails db:create db:migrate  # veritabanı
ruby bin/rails db:seed               # demo verisi (idempotent olmalı)
ruby bin/rails server                # sunucu, /up yeşil dönmeli
```
Veritabanı şifresi kodda değil `PGPASSWORD` ortam değişkenindedir. Şifreyi hiçbir dosyaya, çıktıya veya commit'e yazma.

## Marka kuralı
Ürün adı TempoDesk. Orijinal ürünün adı (ilham kaynağı) README dışında **hiçbir yerde** geçmez: kod, görünüm, `<title>`, favicon, seed, yorum satırı, dosya adı. Her aşama sonunda şunu çalıştır, sonuç boş olmalı:
```
Get-ChildItem -Recurse -File -Exclude README.md | Select-String -Pattern "zendesk" -List | Where-Object { $_.Path -notmatch "\\\.git\\|node_modules|\\log\\|\\tmp\\" }
```

## Kod kuralları
- **Enum:** `status` ve `priority` enum'larında `prefix: true` zorunlu (`new` değeri `Ticket.new` ile çakışır).
- **SLA tek yerde:** Süre kuralı yalnızca `app/models/sla_policy.rb` içinde yaşar. Başka dosyada `4.hours` gibi süre sabiti yazma.
- **İhlal hesaplanır:** `sla_breached` diye veritabanı sütunu veya zamanlayıcı iş yok. `Ticket#sla_breached?` bir metottur.
- **`due_at`:** `before_validation :set_initial_due_at, on: :create` ile atanır (doğrulamadan önce). Sütun `null: false`.
- **Durum geçişi:** `Ticket#transition_to!` kullanılır, izinsiz geçiş `Ticket::InvalidTransition` fırlatır. Durumu doğrudan `update(status: ...)` ile değiştirme.
- **Zaman testleri:** Zamanı yalnızca testlerde `travel_to` ile değiştir. Canlı uygulamada zamanı değiştiren arayüz veya gizli rota yok.
- **Seed:** `find_or_create_by!` ile idempotent. Süresi dolmuş bilet için `created_at` ve `due_at` açıkça verilir.
- **Kimlik doğrulama:** Rails 8 yerleşik üreteci. Herkese açık controller'lar `allow_unauthenticated_access` kullanır. Temsilci şifresi `ENV["AGENT_PASSWORD"]`'dan gelir.
- Sade ERB, JavaScript sayaç yok. Gereksiz gem ekleme, eklemeden önce sor.

## Yasaklar
- Ödeme veya kart bilgisi akışı
- Kapsam dışı özellikler (e-posta bildirimi, otomatik kapanma, canlı sayaç, çoklu kanal vb.)
- Gizli bilgiyi (şifre, `master.key`, `.env`) commit etmek veya çıktıya yazmak
- Test çalıştırmadan "geçti" demek
- Rapor uydurmak. Yapılamayanı yapılamadı diye yaz.

## Rapor biçimi
Her aşama sonunda: (1) yapılanlar, (2) çalıştırılan komutlar ve gerçek çıktıları, (3) yapılamayanlar ve nedenleri, (4) insanın yapması gerekenler.