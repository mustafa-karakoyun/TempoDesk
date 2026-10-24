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

  def new
    @expense = Expense.new(spent_on: Date.current, submitted_by: "demo-agent-01")
  end

  def create
    amount_in_try = params[:amount_try].to_s.tr(",", ".").to_f
    amount_cents = (amount_in_try * 100).round

    expense_params = {
      amount_cents: amount_cents,
      merchant: params[:merchant].to_s.strip,
      category: params[:category].to_s.strip,
      description: params[:description].to_s.strip,
      spent_on: params[:spent_on].presence || Date.current,
      submitted_by: params[:submitted_by].presence || "demo-agent-01"
    }

    intake = ExpenseIntake.new
    @expense = intake.process(expense_params)

    if @expense.persisted?
      if @expense.status_approved?
        redirect_to manager_expenses_path, notice: "✅ Harcama sisteme girildi ve Kâhya (Gemini) tarafından OTOMATİK ONAYLANDI! (Gerekçe: #{@expense.llm_reason})"
      else
        redirect_to manager_expense_path(@expense), notice: "⚠️ Harcama Kâhya (Gemini) tarafından İNCELEMEYE ALINDI (Risk Skoru: %#{@expense.risk_score}). Gerekçe: #{@expense.llm_reason}"
      end
    else
      flash.now[:alert] = "Harcama kaydedilemedi: #{@expense.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
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
