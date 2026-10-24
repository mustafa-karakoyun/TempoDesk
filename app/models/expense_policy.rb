class ExpensePolicy
  AUTO_APPROVE_LIMIT_CENTS = 100_000      # 1.000 TRY
  CFO_THRESHOLD_CENTS      = 500_000      # 5.000 TRY
  ESCALATION_AFTER         = 24.hours

  def self.approver_role_for(expense)
    amount = expense.respond_to?(:amount_cents) ? expense.amount_cents : expense.to_i
    amount > CFO_THRESHOLD_CENTS ? "cfo" : "manager"
  end

  def self.auto_approvable?(expense)
    amount = expense.respond_to?(:amount_cents) ? expense.amount_cents : expense.to_i
    amount <= AUTO_APPROVE_LIMIT_CENTS
  end

  def self.review_due_at(from: Time.current)
    from + ESCALATION_AFTER
  end
end
