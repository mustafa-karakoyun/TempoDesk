class Manager::ExpensesController < ApplicationController
  before_action :require_manager_or_cfo!
  before_action :set_expense, only: [ :show, :decision ]

  def index
    all_pending = Expense.where(status: :pending_review).order(created_at: :desc)

    @expenses = if current_user.role_cfo?
      all_pending.select { |e| e.effective_approver_role == "cfo" }
    else
      all_pending.select { |e| e.effective_approver_role == "manager" }
    end
  end

  def show
    @events = @expense.expense_events.order(created_at: :asc)
  end

  def decision
    unless @expense.status_pending_review?
      redirect_to manager_expenses_path, alert: "Bu harcama daha önce sonuçlandırılmıştır."
      return
    end

    required_role = @expense.effective_approver_role
    unless current_user.role.to_s == required_role
      render plain: "Bu harcamaya karar verme yetkiniz bulunmamaktadır.", status: :forbidden
      return
    end

    target_status = params[:decision].to_s == "approve" ? "approved" : "rejected"
    note = params[:note].presence || (target_status == "approved" ? "Onaylandı" : "Reddedildi")

    @expense.transition_to!(target_status, actor: current_user.role, reason: note)

    redirect_to manager_expenses_path, notice: "Harcama başarıyla #{target_status == 'approved' ? 'onaylandı' : 'reddedildi'}."
  rescue Expense::InvalidTransition => e
    redirect_to manager_expenses_path, alert: e.message
  end

  private

  def set_expense
    @expense = Expense.find(params[:id])
  end

  def require_manager_or_cfo!
    unless authenticated?
      request_authentication
      return
    end

    unless current_user&.role_manager? || current_user&.role_cfo?
      render plain: "Bu alana erişim yetkiniz bulunmamaktadır.", status: :forbidden
    end
  end
end
