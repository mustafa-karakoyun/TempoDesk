namespace :eval do
  desc "Gerçek Gemini API ile harcama vakalarını değerlendirir ve docs/EVAL_RESULTS.md yazar"
  task llm: :environment do
    api_key = ENV["GEMINI_API_KEY"]
    if api_key.blank?
      puts "çalıştırılmadı: GEMINI_API_KEY ortam değişkeni tanımlı değil"
      exit 0
    end

    cases_path = Rails.root.join("test", "fixtures", "files", "llm_eval_cases.yml")
    unless File.exist?(cases_path)
      puts "Hata: #{cases_path} bulunamadı"
      exit 1
    end

    cases = YAML.safe_load_file(cases_path)
    reviewer = LlmReviewer.new

    results = []
    correct_count = 0

    puts "Gemini Değerlendirme Seti Başlatılıyor (#{cases.size} vaka)..."
    puts "Model: #{ENV['GEMINI_MODEL']}"
    puts "-" * 60

    cases.each_with_index do |c, i|
      expense = Expense.new(
        amount_cents: c["amount_cents"],
        merchant: c["merchant"],
        category: c["category"],
        description: c["description"],
        spent_on: Date.parse(c["spent_on"]),
        submitted_by: c["submitted_by"]
      )

      print "[#{i + 1}/#{cases.size}] #{c['id']} (#{c['merchant']}) inceleniyor... "
      $stdout.flush

      review = reviewer.review(expense)
      actual_verdict = review["verdict"]
      expected_verdict = c["expected_verdict"]
      is_match = (actual_verdict == expected_verdict)
      correct_count += 1 if is_match

      status_label = is_match ? "✓ DOĞRU" : "✗ FARKLI"
      puts "#{status_label} (Beklenen: #{expected_verdict}, Gelen: #{actual_verdict}, Risk: #{review['risk_score']})"

      results << {
        id: c["id"],
        merchant: c["merchant"],
        amount: sprintf("%.2f ₺", c["amount_cents"] / 100.0),
        description: c["description"],
        expected: expected_verdict,
        actual: actual_verdict,
        match: is_match,
        risk_score: review["risk_score"],
        policy_clause: review["policy_clause"],
        reason: review["reason"],
        note: c["note"]
      }

      sleep 1.0
    end

    total = cases.size
    accuracy = (correct_count.to_f / total * 100).round(1)

    puts "-" * 60
    puts "Değerlendirme Tamamlandı: #{correct_count}/#{total} (%#{accuracy})"

    FileUtils.mkdir_p(Rails.root.join("docs"))
    results_path = Rails.root.join("docs", "EVAL_RESULTS.md")

    md = <<~MD
      # Kâhya — LLM Denetim Değerlendirme Sonuçları

      - **Tarih:** #{Time.current.strftime("%d.%m.%Y %H:%M")}
      - **Model:** `#{ENV['GEMINI_MODEL']}`
      - **Toplam Vaka:** #{total}
      - **Doğru Eşleşme:** #{correct_count}/#{total}
      - **Başarı Oranı:** %#{accuracy}

      ---

      ## Vaka Karşılaştırma Tablosu

      | ID | Satıcı | Tutar | Açıklama | Beklenen | Gerçek | Durum | Risk | Politika Maddesi |
      | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
      #{results.map do |r|
        durum_icon = r[:match] ? "✓ Uyumlu" : "✗ Farklı"
        "| `#{r[:id]}` | #{r[:merchant]} | #{r[:amount]} | #{r[:description]} | `#{r[:expected]}` | `#{r[:actual]}` | #{durum_icon} | #{r[:risk_score] || '-'} | #{r[:policy_clause] || '-'} |"
      end.join("\n")}

      ---

      ## Detaylı Gerekçeler

      #{results.map do |r|
        <<~CASE_DETAIL
        ### #{r[:id]}: #{r[:merchant]} (#{r[:amount]})
        - **Açıklama:** #{r[:description]}
        - **Kural Notu:** #{r[:note]}
        - **Beklenen / Gerçek:** `#{r[:expected]}` / `#{r[:actual]}` (#{r[:match] ? 'Uyumlu' : 'Farklı'})
        - **Risk Skoru:** #{r[:risk_score]}
        - **Politika Maddesi:** #{r[:policy_clause]}
        - **LLM Gerekçesi:** #{r[:reason]}
        CASE_DETAIL
      end.join("\n")}
    MD

    File.write(results_path, md)
    puts "Rapor kaydedildi: docs/EVAL_RESULTS.md"
  end
end
