class Comment < ApplicationRecord
  belongs_to :ticket

  enum :author_role, { customer: 0, agent: 1 }, prefix: true

  validates :author_role, :author_name, :body, presence: true
  validate :ticket_accepts_comments, on: :create

  # Temsilci bir `new` bilete ilk yanıtı yazınca bilet otomatik `open` olur.
  after_create :open_ticket_on_first_agent_reply

  private

  def ticket_accepts_comments
    errors.add(:base, "Kapatılmış bilete yorum eklenemez") if ticket&.status_closed?
  end

  def open_ticket_on_first_agent_reply
    ticket.transition_to!("open") if author_role_agent? && ticket.status_new?
  end
end
