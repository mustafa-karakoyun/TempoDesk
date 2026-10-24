require "test_helper"

class ExpensePolicyTest < ActiveSupport::TestCase
  test "auto_approvable? sinir degerleri (tam limit dahil, bir kurus fazlasi haric)" do
    # 1.000 TRY = 100.000 kurus tam limit
    assert ExpensePolicy.auto_approvable?(100_000)
    assert ExpensePolicy.auto_approvable?(Expense.new(amount_cents: 100_000))
    assert ExpensePolicy.auto_approvable?(50_000)

    # 1.000,01 TRY = 100.001 kurus limit ustu
    assert_not ExpensePolicy.auto_approvable?(100_001)
    assert_not ExpensePolicy.auto_approvable?(Expense.new(amount_cents: 100_001))
    assert_not ExpensePolicy.auto_approvable?(250_000)
  end

  test "approver_role_for tutar esiklerinde dogru rol (5.000 TRY'ye kadar manager, ustu cfo)" do
    # 5.000 TRY = 500.000 kurus -> manager
    assert_equal "manager", ExpensePolicy.approver_role_for(500_000)
    assert_equal "manager", ExpensePolicy.approver_role_for(Expense.new(amount_cents: 500_000))
    assert_equal "manager", ExpensePolicy.approver_role_for(100_000)

    # 5.000,01 TRY = 500.001 kurus -> cfo
    assert_equal "cfo", ExpensePolicy.approver_role_for(500_001)
    assert_equal "cfo", ExpensePolicy.approver_role_for(Expense.new(amount_cents: 500_001))
    assert_equal "cfo", ExpensePolicy.approver_role_for(800_000)
  end

  test "review_due_at baslangic zamanina 24 saat ekler" do
    baslangic = Time.zone.local(2026, 10, 24, 10, 0, 0)
    beklenen = Time.zone.local(2026, 10, 25, 10, 0, 0)

    assert_equal beklenen, ExpensePolicy.review_due_at(from: baslangic)
  end
end
