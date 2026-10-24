class Expense < ApplicationRecord
  class InvalidTransition < StandardError; end

  TRANSITIONS = {
    "pending_review" => %w[approved rejected]
  }.freeze

  enum :status, { pending_review: 0, approved: 1, rejected: 2 }, prefix: true
  enum :approver_role, { manager: 0, cfo: 1 }, prefix: true

  has_many :expense_events, dependent: :destroy

  before_validation :set_defaults, on: :create

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :merchant, :category, :description, :spent_on, :submitted_by, presence: true
  validates :review_due_at, presence: true

  def transition_to!(new_status, actor:, reason: nil)
    target = new_status.to_s
    allowed = TRANSITIONS[status] || []
    raise InvalidTransition, "Geçersiz durum geçişi: #{status} -> #{target}" unless allowed.include?(target)

    transaction do
      self.status = target
      self.decided_by = actor
      self.decided_at = Time.current
      save!
      expense_events.create!(
        actor: actor,
        action: target,
        reason: reason
      )
    end
  end

  def escalated?
    status_pending_review? && Time.current > review_due_at
  end

  def effective_approver_role
    escalated? ? "cfo" : approver_role
  end

  private

  def set_defaults
    self.approver_role ||= ExpensePolicy.approver_role_for(self) if amount_cents.present?
    self.review_due_at ||= ExpensePolicy.review_due_at(from: created_at || Time.current)
  end
end
