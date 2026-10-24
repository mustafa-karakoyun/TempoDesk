require "net/http"
require "json"

class LlmReviewer
  POLICY_PATH = Rails.root.join("config", "expense_policy.md")
  DAYS_TR = {
    "Monday" => "Pazartesi", "Tuesday" => "Salı", "Wednesday" => "Çarşamba",
    "Thursday" => "Perşembe", "Friday" => "Cuma", "Saturday" => "Cumartesi", "Sunday" => "Pazar"
  }.freeze

  class LlmError < StandardError; end

  def initialize(client: nil)
    @client = client
  end

  def review(expense)
    prompt = build_prompt(expense)

    attempts = 0
    begin
      attempts += 1
      raw_response = @client ? @client.call(prompt) : make_http_call(prompt)
      parse_and_validate(raw_response)
    rescue => e
      if attempts < 2
        retry
      else
        Rails.logger.warn("LlmReviewer failed: #{e.message}")
        {
          "verdict" => "flag",
          "risk_score" => nil,
          "policy_clause" => nil,
          "reason" => "LLM kullanılamadı",
          "failed" => true
        }
      end
    end
  end

  private

  def policy_content
    @policy_content ||= File.read(POLICY_PATH)
  end

  def build_prompt(expense)
    day_name = expense.spent_on ? DAYS_TR[expense.spent_on.strftime("%A")] : "Bilinmiyor"
    amount_try = sprintf("%.2f ₺", expense.amount_cents.to_i / 100.0)

    <<~PROMPT
      Sen Kâhya kurumsal harcama denetim sisteminin yapay zekâ denetçisisin.
      Aşağıdaki kurumsal harcama politikasını dikkatle oku ve verilen harcamayı denetle.

      --- POLİTİKA BAŞLANGICI ---
      #{policy_content}
      --- POLİTİKA BİTİŞİ ---

      --- DENETLENECEK HARCAMA ---
      Tutar: #{amount_try} (#{expense.amount_cents} kuruş)
      Satıcı: #{expense.merchant}
      Kategori: #{expense.category}
      Açıklama: #{expense.description}
      Harcama Tarihi: #{expense.spent_on} (#{day_name})
      Harcamayı Gönderen: #{expense.submitted_by}
      ----------------------------

      GÖREV:
      1. Harcamayı politika maddelerine göre değerlendir.
      2. Harcama açıkça uygun ve olağan bir harcama ise verdict: "approve" dön.
      3. Harcama şüpheli, politikanın herhangi bir maddesine aykırı, hafta sonu olağan dışı yemek, kişisel eğlence veya tutar/kategori sınırında ise verdict: "flag" dön.
      4. risk_score alanına 0 ile 100 arasında bir risk skoru ata (0: tamamen temiz, 100: ağır ihlal).
      5. policy_clause alanına ilgili politikanın madde numarasını ve kısa adını yaz (ör. "Madde 1", "Madde 4").
      6. reason alanına kararın anlaşılır Türkçe gerekçesini yaz.
    PROMPT
  end

  def make_http_call(prompt)
    api_key = ENV["GEMINI_API_KEY"]
    model = ENV["GEMINI_MODEL"]

    raise LlmError, "GEMINI_API_KEY veya GEMINI_MODEL tanimsiz" if api_key.blank? || model.blank?

    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent?key=#{api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 8
    http.read_timeout = 10

    req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    req.body = {
      contents: [
        { parts: [{ text: prompt }] }
      ],
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: {
          type: "OBJECT",
          properties: {
            verdict: { type: "STRING", enum: %w[approve flag] },
            risk_score: { type: "INTEGER" },
            policy_clause: { type: "STRING" },
            reason: { type: "STRING" }
          },
          required: %w[verdict risk_score policy_clause reason]
        }
      }
    }.to_json

    response = http.request(req)
    raise LlmError, "HTTP #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    response.body
  end

  def parse_and_validate(raw)
    data = raw.is_a?(Hash) ? raw : JSON.parse(raw)

    if data["candidates"].is_a?(Array)
      text_part = data.dig("candidates", 0, "content", "parts", 0, "text")
      raise LlmError, "Gemini yanıtında text alanı yok" if text_part.blank?
      data = JSON.parse(text_part)
    end

    verdict = data["verdict"].to_s.downcase
    raise LlmError, "Geçersiz verdict: #{verdict}" unless %w[approve flag].include?(verdict)

    risk_score = data["risk_score"]
    raise LlmError, "Geçersiz risk_score" unless risk_score.is_a?(Integer) && risk_score.between?(0, 100)

    policy_clause = data["policy_clause"].to_s
    raise LlmError, "policy_clause eksik" if policy_clause.blank?

    reason = data["reason"].to_s
    raise LlmError, "reason eksik" if reason.blank?

    {
      "verdict" => verdict,
      "risk_score" => risk_score,
      "policy_clause" => policy_clause,
      "reason" => reason,
      "failed" => false
    }
  end
end
