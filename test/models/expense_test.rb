require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  def build_expense(**overrides)
    Expense.create!({
      amount_cents: 250_000,
      merchant: "Teknoloji Market",
      category: "Donanım",
      description: "Monitör alımı",
      spent_on: Date.current,
      submitted_by: "TestBot"
    }.merge(overrides))
  end

  # --- Oluşturma ve Varsayılanlar ---

  test "yeni harcama pending_review baslar, approver_role ve review_due_at otomatik atanir" do
    travel_to Time.zone.local(2026, 10, 24, 12, 0, 0) do
      # 2.500 TRY (<= 5.000 TRY) -> manager
      expense = build_expense(amount_cents: 250_000)
      assert expense.status_pending_review?
      assert expense.approver_role_manager?
      assert_equal ExpensePolicy.review_due_at(from: Time.current), expense.review_due_at
    end
  end

  test "5.000 TL ustu harcamada approver_role cfo atanir" do
    expense = build_expense(amount_cents: 600_000)
    assert expense.approver_role_cfo?
  end

  test "gecersiz tutar ve bos alanlar reddedilir" do
    expense = Expense.new(amount_cents: 0, merchant: "", description: "")
    assert_not expense.valid?
    assert expense.errors[:amount_cents].any?
    assert expense.errors[:merchant].any?
    assert expense.errors[:description].any?
  end

  # --- Durum Geçişleri ve Denetim Kaydı (Audit Log) ---

  test "izinli gecisler calisir ve expense_events kaydi olusur" do
    # pending_review -> approved
    exp1 = build_expense
    assert_difference "exp1.expense_events.count", 1 do
      exp1.transition_to!("approved", actor: "manager", reason: "Uygundur")
    end
    assert exp1.status_approved?
    assert_equal "manager", exp1.decided_by
    assert exp1.decided_at.present?

    event = exp1.expense_events.last
    assert_equal "manager", event.actor
    assert_equal "approved", event.action
    assert_equal "Uygundur", event.reason

    # pending_review -> rejected
    exp2 = build_expense
    assert_difference "exp2.expense_events.count", 1 do
      exp2.transition_to!("rejected", actor: "manager", reason: "Gerekce yetersiz")
    end
    assert exp2.status_rejected?
    assert_equal "manager", exp2.decided_by
    assert exp2.decided_at.present?
  end

  test "izinsiz gecisler InvalidTransition firlatir" do
    expense = build_expense
    expense.transition_to!("approved", actor: "manager")

    assert_raises Expense::InvalidTransition do
      expense.transition_to!("rejected", actor: "manager")
    end

    assert_raises Expense::InvalidTransition do
      expense.transition_to!("pending_review", actor: "manager")
    end
  end

  # --- Eskalasyon Mantığı (travel_to) ---

  test "travel_to ile eskalasyon: 23 sa 59 dk sonra escalated? false, 24 sa 1 dk sonra true" do
    start_time = Time.zone.local(2026, 10, 24, 10, 0, 0)

    travel_to start_time do
      expense = build_expense(amount_cents: 250_000)
      assert_equal "manager", expense.effective_approver_role
      assert_not expense.escalated?

      # 23 saat 59 dakika sonra
      travel 23.hours + 59.minutes
      assert_not expense.escalated?
      assert_equal "manager", expense.effective_approver_role

      # 2 dakika daha sonra (toplam 24 saat 1 dakika)
      travel 2.minutes
      assert expense.escalated?
      assert_equal "cfo", expense.effective_approver_role
    end
  end

  test "karar verilmis harcama asla escalated? olmaz" do
    start_time = Time.zone.local(2026, 10, 24, 10, 0, 0)

    travel_to start_time do
      expense = build_expense(amount_cents: 250_000)
      expense.transition_to!("approved", actor: "manager")

      # 48 saat sonra bile onaylanmış harcama eskale sayılmaz
      travel 48.hours
      assert_not expense.escalated?
      assert_equal "manager", expense.effective_approver_role
    end
  end
end
