class Ticket < ApplicationRecord
  class InvalidTransition < StandardError; end

  TRANSITIONS = {
    "new"    => %w[open],
    "open"   => %w[solved],
    "solved" => %w[closed open]
  }.freeze

  has_secure_token :access_token
  has_many :comments, dependent: :destroy

  # prefix: true zorunlu: aksi hâlde `new` değeri Ticket.new ile çakışır.
  enum :priority, { low: 0, normal: 1, high: 2, urgent: 3 }, prefix: true
  enum :status, { new: 0, open: 1, solved: 2, closed: 3 }, prefix: true

  # due_at doğrulamadan ÖNCE atanır (before_create doğrulamadan sonra çalışırdı).
  before_validation :set_initial_due_at, on: :create

  validates :title, :description, presence: true
  validates :customer_email, presence: true,
                             format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :priority, :status, :due_at, presence: true

  # Durumu yalnızca bu metot değiştirir. İzinsiz geçişte InvalidTransition fırlatır.
  def transition_to!(new_status, resolution_summary: nil)
    new_status = new_status.to_s
    allowed = TRANSITIONS.fetch(status, [])

    unless allowed.include?(new_status)
      raise InvalidTransition, "#{status} durumundan #{new_status} durumuna geçilemez"
    end

    attrs = { status: new_status }
    attrs[:solved_at] = Time.current if new_status == "solved"
    attrs[:solved_at] = nil if new_status == "open"
    attrs[:resolution_summary] = resolution_summary if resolution_summary.present?
    update!(attrs)
  end

  # İhlal saklanmaz, hesaplanır. Çözülmüşse çözüm anına, değilse şimdiye bakılır.
  def sla_breached?
    (solved_at || Time.current) > due_at
  end

  # Çözülmemiş bilet için SLA bitimine kalan saniye (ihlalde negatif/sıfır).
  def sla_seconds_remaining
    (due_at - Time.current).to_i
  end

  def resolved?
    status_solved? || status_closed?
  end

  private

  def set_initial_due_at
    self.due_at ||= SlaPolicy.due_at(priority: priority) if priority.present?
  end
end
