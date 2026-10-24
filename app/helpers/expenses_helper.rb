module ExpensesHelper
  def escalation_label(expense)
    return unless expense.status_pending_review?

    if expense.escalated?
      "Eskale edildi: CFO"
    else
      remaining_seconds = [ (expense.review_due_at - Time.current).to_i, 0 ].max
      total_minutes = remaining_seconds / 60
      hours, minutes = total_minutes.divmod(60)

      duration_text = if total_minutes.zero?
        "1 dk'dan az"
      elsif hours.zero?
        "#{minutes} dk"
      elsif minutes.zero?
        "#{hours} sa"
      else
        "#{hours} sa #{minutes} dk"
      end

      "#{duration_text} içinde karar bekleniyor"
    end
  end

  def expense_amount_tag(expense)
    sprintf("%.2f ₺", expense.amount_cents / 100.0)
  end
end
