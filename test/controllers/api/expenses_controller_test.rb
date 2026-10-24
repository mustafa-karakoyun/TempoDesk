require "test_helper"

class Api::ExpensesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_key = "test-agent-secret-key"
    @original_key = ENV["AGENT_API_KEY"]
    ENV["AGENT_API_KEY"] = @api_key

    @valid_payload = {
      amount_cents: 80_000,
      merchant: "Ofis Kırtasiye Ltd.",
      category: "Ofis Malzemeleri",
      description: "Yazıcı kartuşu",
      spent_on: Date.current.to_s,
      submitted_by: "TestBot"
    }

    @original_builder = ExpenseIntake.default_reviewer_builder
  end

  teardown do
    ENV["AGENT_API_KEY"] = @original_key
    ExpenseIntake.default_reviewer_builder = @original_builder
  end

  test "Authorization basligi olmadan 401 Unauthorized doner" do
    post api_expenses_path, params: @valid_payload, as: :json
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_includes json["error"], "Yetkisiz"
  end

  test "Yanlis API anahtari ile 401 Unauthorized doner" do
    post api_expenses_path,
         params: @valid_payload,
         headers: { "Authorization" => "Bearer yanlis-anahtar" },
         as: :json

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_includes json["error"], "Yetkisiz"
  end

  test "Gecerli API anahtari ve gecerli veri ile 201 Created doner" do
    stub_reviewer = Object.new
    def stub_reviewer.review(expense)
      {
        "verdict" => "approve",
        "risk_score" => 5,
        "policy_clause" => "Madde 1",
        "reason" => "Limit alti onay",
        "failed" => false
      }
    end

    ExpenseIntake.default_reviewer_builder = -> { stub_reviewer }

    post api_expenses_path,
         params: @valid_payload,
         headers: { "Authorization" => "Bearer #{@api_key}" },
         as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert json["id"].present?
    assert_equal "approved", json["status"]
    assert_equal "approve", json["verdict"]
    assert_equal 5, json["risk_score"]
    assert_equal "Madde 1", json["policy_clause"]
  end

  test "Gecersiz govde ile 422 Unprocessable Entity doner" do
    invalid_payload = @valid_payload.merge(amount_cents: 0, merchant: "")

    post api_expenses_path,
         params: invalid_payload,
         headers: { "Authorization" => "Bearer #{@api_key}" },
         as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["errors"].present?
  end
end
