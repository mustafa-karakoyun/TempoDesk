class Api::ExpensesController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :verify_authenticity_token
  before_action :authenticate_agent_api_key!

  def create
    expense = ExpenseIntake.new.process(expense_params)

    if expense.persisted?
      render json: {
        id: expense.id,
        status: expense.status,
        verdict: expense.verdict,
        risk_score: expense.risk_score,
        policy_clause: expense.policy_clause,
        reason: expense.llm_reason,
        approver_role: expense.approver_role
      }, status: :created
    else
      render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def authenticate_agent_api_key!
    expected_key = ENV["AGENT_API_KEY"]
    if expected_key.blank?
      render json: { error: "Yetkisiz erişim: AGENT_API_KEY yapılandırılmamış" }, status: :unauthorized
      return
    end

    auth_header = request.headers["Authorization"].to_s
    token = auth_header.start_with?("Bearer ") ? auth_header.split(" ", 2).last.strip : ""

    unless token.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected_key)
      render json: { error: "Yetkisiz erişim: Geçersiz veya eksik API anahtarı" }, status: :unauthorized
    end
  end

  def expense_params
    raw_params = params.key?(:expense) ? params.require(:expense) : params
    raw_params.permit(
      :amount_cents,
      :merchant,
      :category,
      :description,
      :spent_on,
      :submitted_by
    )
  end
end
