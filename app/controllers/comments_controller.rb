class CommentsController < ApplicationController
  allow_unauthenticated_access

  def create
    @ticket = Ticket.find_by!(access_token: params[:access_token])

    if @ticket.status_closed?
      redirect_to customer_ticket_path(@ticket.access_token), alert: "Kapatılmış bir bilete yeni yanıt eklenemez."
      return
    end

    @comment = @ticket.comments.build(comment_params)
    @comment.author_role = :customer

    if @comment.save
      redirect_to customer_ticket_path(@ticket.access_token), notice: "Yanıtınız başarıyla iletildi."
    else
      @comments = @ticket.comments.order(created_at: :asc)
      @new_comment = @comment
      flash.now[:alert] = "Yanıt gönderilemedi: #{@comment.errors.full_messages.to_sentence}"
      render "tickets/show", status: :unprocessable_entity
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:author_name, :body)
  end
end
