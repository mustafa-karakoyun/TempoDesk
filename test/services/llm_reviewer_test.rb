require "test_helper"

class LlmReviewerTest < ActiveSupport::TestCase
  def build_expense
    Expense.new(
      amount_cents: 90_000,
      merchant: "Ofis Kırtasiye",
      category: "Ofis Malzemeleri",
      description: "Kağıt alımı",
      spent_on: Date.current,
      submitted_by: "TestBot"
    )
  end

  test "bozuk sema bir kez yeniden denenir ve ikinci denemede basarili olursa gecerli sonuc doner" do
    calls = 0
    fake_client = lambda do |_prompt|
      calls += 1
      if calls == 1
        "bozuk-json-cikti" # İlk deneme hata fırlatır
      else
        {
          "candidates" => [
            {
              "content" => {
                "parts" => [
                  {
                    "text" => {
                      "verdict" => "approve",
                      "risk_score" => 10,
                      "policy_clause" => "Madde 1",
                      "reason" => "İkinci denemede başarılı"
                    }.to_json
                  }
                ]
              }
            }
          ]
        }.to_json
      end
    end

    reviewer = LlmReviewer.new(client: fake_client)
    result = reviewer.review(build_expense)

    assert_equal 2, calls, "Bozuk şema bir kez yeniden denenmeli (toplam 2 çağrı)"
    assert_equal "approve", result["verdict"]
    assert_equal 10, result["risk_score"]
    assert_equal "Madde 1", result["policy_clause"]
    assert_not result["failed"]
  end

  test "iki deneme de basarisiz olursa fail-closed sonuc doner" do
    calls = 0
    fake_client = lambda do |_prompt|
      calls += 1
      raise Net::ReadTimeout, "Zaman aşımı"
    end

    reviewer = LlmReviewer.new(client: fake_client)
    result = reviewer.review(build_expense)

    assert_equal 2, calls
    assert_equal "flag", result["verdict"]
    assert_equal "LLM kullanılamadı", result["reason"]
    assert result["failed"]
  end
end
