class ExpenseIntake
  cattr_accessor :default_reviewer_builder, default: -> { LlmReviewer.new }

  def initialize(llm_reviewer: nil)
    @llm_reviewer = llm_reviewer || self.class.default_reviewer_builder.call
  end

  def process(params)
    expense = Expense.new(params)
    return expense unless expense.valid?

    ActiveRecord::Base.transaction do
      expense.save!

      review_result = @llm_reviewer.review(expense)

      expense.verdict = review_result["verdict"]
      expense.risk_score = review_result["risk_score"]
      expense.policy_clause = review_result["policy_clause"]
      expense.llm_reason = review_result["reason"]

      if review_result["verdict"] == "approve" && ExpensePolicy.auto_approvable?(expense) && !review_result["failed"]
        expense.transition_to!("approved", actor: "llm", reason: review_result["reason"])
      else
        expense.save!
        event_reason = review_result["failed"] ? "LLM kullanılamadı" : (review_result["reason"].presence || "Harcama sisteme iletildi")
        expense.expense_events.create!(
          actor: expense.submitted_by.presence || "agent",
          action: "submitted",
          reason: event_reason
        )
      end
    end

    expense
  end
end
