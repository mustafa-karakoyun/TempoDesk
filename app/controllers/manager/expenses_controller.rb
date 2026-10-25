class Manager::ExpensesController < ApplicationController
  before_action :require_manager_or_cfo!
  before_action :set_expense, only: [ :show, :decision ]

  def index
    @current_tab = params[:tab].presence || "pending"

    @pending_count = Expense.where(status: :pending_review).count
    @approved_count = Expense.where(status: :approved).count
    @rejected_count = Expense.where(status: :rejected).count

    @expenses = case @current_tab
    when "approved"
                  Expense.where(status: :approved).order(decided_at: :desc, created_at: :desc)
    when "rejected"
                  Expense.where(status: :rejected).order(decided_at: :desc, created_at: :desc)
    else
                  all_pending = Expense.where(status: :pending_review).order(created_at: :desc)
                  if current_user.role_cfo?
                    all_pending.select { |e| e.effective_approver_role == "cfo" }
                  else
                    all_pending.select { |e| e.effective_approver_role == "manager" }
                  end
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

  def simulate_agent
    scenarios = [
      {
        merchant: "AWS Cloud Infrastructure",
        category: "Yazılım",
        amount_cents: 68_000,
        description: "Production ortamı için dinamik bellek ve CPU kapasite artırımı",
        submitted_by: "DevOpsAgent-01"
      },
      {
        merchant: "TCDD & İbis Otel",
        category: "Seyahat",
        amount_cents: 245_000,
        description: "Ankara müşteri sunumu için hızlı tren bileti ve 1 gece standart konaklama",
        submitted_by: "TravelBot-03"
      },
      {
        merchant: "Ofis Market Sarf Ltd.",
        category: "Ofis",
        amount_cents: 38_000,
        description: "Yazıcı için siyah toner kartuşu ve A4 fotokopi kağıdı paketi",
        submitted_by: "ProcurementBot-09"
      },
      {
        merchant: "Boğaziçi Balık Restoranı",
        category: "Yemek",
        amount_cents: 185_000,
        description: "Yurt dışı iş ortağı ile akşam yemeğinde 2 kadeh kırmızı şarap ve ikram",
        submitted_by: "SalesAgent-02"
      },
      {
        merchant: "Dell Yetkili Dağıtıcı",
        category: "Donanım",
        amount_cents: 680_000,
        description: "Yeni sistem mimarı için Dell UltraSharp 32 inç 4K profesyonel monitör",
        submitted_by: "ITProvisioner-04"
      }
    ]

    scenario = scenarios.sample
    expense_params = scenario.merge(spent_on: Date.current)

    intake = ExpenseIntake.new
    @expense = intake.process(expense_params)

    if @expense.persisted?
      if @expense.status_approved?
        redirect_to manager_expenses_path(tab: "approved"), notice: "🤖 Otonom Ajan (#{@expense.submitted_by}) 1 harcama iletti. Kâhya (Gemini) inceledi ve OTOMATİK ONAYLADI! Onaylanan Harcamalar sekmesinde görüntüleniyor. (Gerekçe: #{@expense.llm_reason})"
      else
        redirect_to manager_expense_path(@expense), notice: "🤖 Otonom Ajan (#{@expense.submitted_by}) 1 harcama iletti. Kâhya (Gemini) İNCELEMEYE ALINDI (Risk Skoru: %#{@expense.risk_score}). Gerekçe: #{@expense.llm_reason}"
      end
    else
      redirect_to manager_expenses_path, alert: "Ajan harcaması oluşturulamadı: #{@expense.errors.full_messages.join(', ')}"
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
