module Agent
  class TicketsController < ApplicationController
    before_action :set_ticket, only: [ :show, :transition ]

    def index
      # İhlalliler ve süresi yaklaşanlar önce gelecek şekilde sıralama:
      # Aktif biletler (new=0, open=1) önce listelenir, aralarında en erken due_at (yani süresi geçmiş veya yaklaşanlar) en üstte çıkar.
      base_scope = Ticket.all

      @filter = params[:filter].presence || "active"
      @tickets = case @filter
                 when "all"
                   base_scope
                 when "solved"
                   base_scope.where(status: :solved)
                 when "closed"
                   base_scope.where(status: :closed)
                 else # "active" default
                   base_scope.where(status: [ :new, :open ])
      end

      # İhlalliler (due_at geçmiş olanlar) ve süresi yaklaşanlar önce
      @tickets = @tickets.order(
        Arel.sql("CASE WHEN status IN (0, 1) THEN 0 ELSE 1 END, due_at ASC")
      )

      # İstatistik sayaçları
      @active_count = Ticket.where(status: [ :new, :open ]).count
      @breached_count = Ticket.where(status: [ :new, :open ]).where("due_at < ?", Time.current).count
      @solved_count = Ticket.where(status: [ :solved, :closed ]).count
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
