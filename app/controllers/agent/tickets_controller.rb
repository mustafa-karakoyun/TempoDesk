module Agent
  class TicketsController < ApplicationController
    before_action :set_ticket, only: [ :show, :transition ]

    def index
      # İhlalliler ve süresi yaklaşanlar önce gelecek şekilde sıralanmış bilet listesi:
      # Aktif biletler (new=0, open=1) önce listelenir, aralarında en erken due_at en üstte çıkar.
      @tickets = Ticket.order(
        Arel.sql("CASE WHEN status IN (0, 1) THEN 0 ELSE 1 END, due_at ASC")
      )
    end

    def show
      @comments = @ticket.comments.order(created_at: :asc)
      agent_name = Current.session&.user&.email_address || "Destek Temsilcisi"
      @new_comment = Comment.new(author_name: agent_name)
    end

    def transition
      new_status = params[:status]

      begin
        @ticket.transition_to!(new_status)
        redirect_to agent_ticket_path(@ticket), notice: "Bilet durumu '#{helpers.status_label(@ticket.status)}' olarak güncellendi."
      rescue Ticket::InvalidTransition => e
        redirect_to agent_ticket_path(@ticket), alert: "Geçersiz durum geçişi: #{e.message}"
      end
    end

    private

    def set_ticket
      @ticket = Ticket.find(params[:id])
    end
  end
end
