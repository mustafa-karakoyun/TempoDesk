require "test_helper"

class ExpensesHelperTest < ActionView::TestCase
  include ExpensesHelper

  test "escalation_label metinleri: kalan sure ve eskale durumu" do
    start_time = Time.zone.local(2026, 10, 24, 10, 0, 0)

    travel_to start_time do
      expense = Expense.create!(
        amount_cents: 200_000,
        merchant: "Market",
        category: "Gıda",
        description: "İkram",
        spent_on: Date.current,
        submitted_by: "TestBot",
        review_due_at: start_time + 23.hours + 10.minutes
      )

      # 23 saat 10 dakika kalmış
      assert_equal "23 sa 10 dk içinde karar bekleniyor", escalation_label(expense)

      # Süre aşıldığında
      travel 25.hours
      assert expense.escalated?
      assert_equal "Eskale edildi: CFO", escalation_label(expense)

      # Karar verildiğinde label nil döner
      expense.transition_to!("approved", actor: "cfo")
      assert_nil escalation_label(expense)
    end
  end
end
