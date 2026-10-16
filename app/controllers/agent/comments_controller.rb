module Agent
  class CommentsController < ApplicationController
    before_action :set_ticket

    def create
      if @ticket.status_closed?
        redirect_to agent_ticket_path(@ticket), alert: "Kapatılmış bir bilete yeni yanıt eklenemez."
        return
      end

      default_agent_name = Current.session&.user&.email_address || "Destek Temsilcisi"

      @comment = @ticket.comments.build(comment_params)
      @comment.author_role = :agent
      @comment.author_name = default_agent_name if @comment.author_name.blank?

      if @comment.save
        # Comment modelindeki after_create :open_ticket_on_first_agent_reply
        # callback'i ile bilet 'new' durumundaysa otomatik 'open' durumuna geçer.
        notice_text = "Yanıtınız başarıyla eklendi."
        notice_text += " (Bilet durumu 'Açık' olarak güncellendi)" if @ticket.reload.status_open?
        redirect_to agent_ticket_path(@ticket), notice: notice_text
      else
        @comments = @ticket.comments.order(created_at: :asc)
        @new_comment = @comment
        flash.now[:alert] = "Yanıt kaydedilemedi: #{@comment.errors.full_messages.to_sentence}"
        render "agent/tickets/show", status: :unprocessable_entity
      end
    end

    private

    def set_ticket
      @ticket = Ticket.find(params[:ticket_id])
    end

    def comment_params
      params.require(:comment).permit(:body, :author_name)
    end
  end
end
