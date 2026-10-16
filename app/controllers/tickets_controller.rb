class TicketsController < ApplicationController
  allow_unauthenticated_access

  def new
    @ticket = Ticket.new(priority: :normal)
  end

  def create
    @ticket = Ticket.new(ticket_params)

    if @ticket.save
      redirect_to customer_ticket_path(@ticket.access_token), notice: "Destek biletiniz başarıyla oluşturuldu. Bu bağlantıyı saklayarak durumu takip edebilirsiniz."
    else
      flash.now[:alert] = "Lütfen formdaki hataları kontrol ediniz."
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @ticket = Ticket.find_by!(access_token: params[:access_token])
    @comments = @ticket.comments.order(created_at: :asc)
    @new_comment = Comment.new(author_name: @ticket.customer_email.split("@").first)
  end

  private

  def ticket_params
    params.require(:ticket).permit(:title, :description, :customer_email, :priority)
  end
end
