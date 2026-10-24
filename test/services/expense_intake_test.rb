require "test_helper"

class ExpenseIntakeTest < ActiveSupport::TestCase
  def valid_attributes(overrides = {})
    {
      amount_cents: 80_000,
      merchant: "Ofis Kırtasiye",
      category: "Ofis Malzemeleri",
      description: "Fotokopi kağıdı",
      spent_on: Date.current,
      submitted_by: "TestBot"
    }.merge(overrides)
  end

  test "stub approve + limit alti harcama approved durumuna gecer ve decided_by llm olur" do
    stub_reviewer = Object.new
    def stub_reviewer.review(expense)
      {
        "verdict" => "approve",
        "risk_score" => 10,
        "policy_clause" => "Madde 1",
        "reason" => "Limit alti ofis harcamasi",
        "failed" => false
      }
    end

    intake = ExpenseIntake.new(llm_reviewer: stub_reviewer)
    expense = intake.process(valid_attributes(amount_cents: 80_000)) # 800 TRY <= 1.000 TRY

    assert expense.persisted?
    assert expense.status_approved?
    assert_equal "llm", expense.decided_by
    assert expense.decided_at.present?
    assert_equal "approve", expense.verdict
    assert_equal 10, expense.risk_score
    assert_equal "Madde 1", expense.policy_clause

    event = expense.expense_events.last
    assert_equal "llm", event.actor
    assert_equal "approved", event.action
    assert_equal "Limit alti ofis harcamasi", event.reason
  end

  test "stub approve + limit ustu harcamada LLM sert kurali asamaz ve pending_review kalir" do
    stub_reviewer = Object.new
    def stub_reviewer.review(expense)
      {
        "verdict" => "approve",
        "risk_score" => 20,
        "policy_clause" => "Madde 3",
        "reason" => "LLM onayladi ancak tutar 1.000 TL ustu",
        "failed" => false
      }
    end

    intake = ExpenseIntake.new(llm_reviewer: stub_reviewer)
    expense = intake.process(valid_attributes(amount_cents: 250_000)) # 2.500 TRY > 1.000 TRY limit

    assert expense.persisted?
    assert expense.status_pending_review?, "Limit üstü harcama LLM onaylasa bile pending_review kalmalı"
    assert_nil expense.decided_by
    assert_nil expense.decided_at
    assert_equal "approve", expense.verdict
    assert_equal 20, expense.risk_score
    assert_equal "Madde 3", expense.policy_clause
    assert_equal "LLM onayladi ancak tutar 1.000 TL ustu", expense.llm_reason

    event = expense.expense_events.last
    assert_equal "TestBot", event.actor
    assert_equal "submitted", event.action
  end

  test "stub flag durumunda pending_review kalir, gerekce ve madde kaydedilir" do
    stub_reviewer = Object.new
    def stub_reviewer.review(expense)
      {
        "verdict" => "flag",
        "risk_score" => 65,
        "policy_clause" => "Madde 4",
        "reason" => "Ağırlama harcaması kişi başı limit şüphesi",
        "failed" => false
      }
    end

    intake = ExpenseIntake.new(llm_reviewer: stub_reviewer)
    expense = intake.process(valid_attributes(amount_cents: 80_000))

    assert expense.persisted?
    assert expense.status_pending_review?
    assert_equal "flag", expense.verdict
    assert_equal 65, expense.risk_score
    assert_equal "Madde 4", expense.policy_clause
    assert_equal "Ağırlama harcaması kişi başı limit şüphesi", expense.llm_reason

    event = expense.expense_events.last
    assert_equal "submitted", event.action
    assert_equal "Ağırlama harcaması kişi başı limit şüphesi", event.reason
  end

  test "stub hata / zaman asimi durumunda fail-closed ile pending_review kalir ve LLM kullanilamadi kaydedilir" do
    stub_reviewer = Object.new
    def stub_reviewer.review(expense)
      {
        "verdict" => "flag",
        "risk_score" => nil,
        "policy_clause" => nil,
        "reason" => "LLM kullanılamadı",
        "failed" => true
      }
    end

    intake = ExpenseIntake.new(llm_reviewer: stub_reviewer)
    expense = intake.process(valid_attributes(amount_cents: 50_000))

    assert expense.persisted?
    assert expense.status_pending_review?, "Fail-closed: LLM hatasında onaylanmamalı, pending kalmalı"
    assert_nil expense.decided_by
    assert_equal "LLM kullanılamadı", expense.llm_reason

    event = expense.expense_events.last
    assert_equal "LLM kullanılamadı", event.reason
  end
end
