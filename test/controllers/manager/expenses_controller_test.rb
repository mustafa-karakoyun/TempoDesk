require "test_helper"

class Manager::ExpensesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @manager_user = User.create!(
      email_address: "test_manager@kahya.example",
      password: "password123",
      role: :manager
    )

    @cfo_user = User.create!(
      email_address: "test_cfo@kahya.example",
      password: "password123",
      role: :cfo
    )

    @agent_user = User.create!(
      email_address: "test_agent_only@kahya.example",
      password: "password123",
      role: :agent
    )

    @manager_expense = Expense.create!(
      amount_cents: 250_000, # 2.500 TRY -> manager
      merchant: "Akdeniz Balıkçısı",
      category: "Temsil",
      description: "İş yemeği",
      spent_on: Date.current,
      submitted_by: "TravelBot"
    )

    @cfo_expense = Expense.create!(
      amount_cents: 800_000, # 8.000 TRY -> cfo
      merchant: "Apple Store",
      category: "Donanım",
      description: "MacBook alımı",
      spent_on: Date.current,
      submitted_by: "ITBot"
    )
  end

  # --- Erişim & Yetkilendirme ---

  test "girissiz kullanici /manager/expenses acamaz, girise yonlendirilir" do
    get manager_expenses_path
    assert_redirected_to new_session_path
  end

  test "agent rolu /manager/expenses acamaz, 403 Forbidden doner" do
    sign_in_as @agent_user
    get manager_expenses_path
    assert_response :forbidden
  end

  test "manager kendi kartlarini gorur, cfo kartlarini gormez" do
    sign_in_as @manager_user
    get manager_expenses_path
    assert_response :success
    assert_includes response.body, "Akdeniz Balıkçısı"
    assert_not_includes response.body, "Apple Store"
  end

  test "cfo kendi kartlarini gorur" do
    sign_in_as @cfo_user
    get manager_expenses_path
    assert_response :success
    assert_includes response.body, "Apple Store"
    assert_not_includes response.body, "Akdeniz Balıkçısı"
  end

  # --- Karar Verme & Yetki Matrisi ---

  test "manager kendi kartina onay karari verebilir, durum guncellenir ve event olusur" do
    sign_in_as @manager_user

    assert_difference "@manager_expense.expense_events.count", 1 do
      patch decision_manager_expense_path(@manager_expense), params: { decision: "approve", note: "Uygun goruldu" }
    end

    assert_redirected_to manager_expenses_path
    @manager_expense.reload
    assert @manager_expense.status_approved?
    assert_equal "manager", @manager_expense.decided_by
    assert_equal "manager", @manager_expense.expense_events.last.actor
    assert_equal "Uygun goruldu", @manager_expense.expense_events.last.reason
  end

  test "manager cfo kartina karar veremez, 403 Forbidden doner" do
    sign_in_as @manager_user
    patch decision_manager_expense_path(@cfo_expense), params: { decision: "approve" }
    assert_response :forbidden
  end

  test "karar verilmis kayda tekrar karar verilemez, flash uyarisi ile yonlendirilir" do
    sign_in_as @manager_user
    @manager_expense.transition_to!("approved", actor: "manager", reason: "Ilk onay")

    patch decision_manager_expense_path(@manager_expense), params: { decision: "reject" }
    assert_redirected_to manager_expenses_path
    follow_redirect!
    assert_includes response.body, "daha önce sonuçlandırılmıştır"
  end

  # --- Eskalasyon & CFO Geçişi (travel_to) ---

  test "travel_to ile 24 saat 1 dakika sonra manager karti eskale olur ve cfo ekranina duser" do
    start_time = Time.zone.local(2026, 10, 24, 10, 0, 0)

    travel_to start_time do
      exp = Expense.create!(
        amount_cents: 200_000,
        merchant: "Eskale Olacak Restoran",
        category: "Yemek",
        description: "Yemek harcaması",
        spent_on: Date.current,
        submitted_by: "TestBot"
      )

      # 24 saat 1 dakika sonra
      travel 24.hours + 1.minute
      assert exp.escalated?

      # CFO giriş yapıp baktığında bu eskale harcamayı görür
      sign_in_as @cfo_user
      get manager_expenses_path
      assert_response :success
      assert_includes response.body, "Eskale Olacak Restoran"
      assert_includes response.body, "Eskale edildi: CFO"

      # CFO karar verebilir
      patch decision_manager_expense_path(exp), params: { decision: "approve", note: "CFO gecikmeli onay" }
      assert_redirected_to manager_expenses_path
      assert exp.reload.status_approved?
    end
  end

  # --- Detay ve Denetim İzi Zaman Çizelgesi ---

  test "harcama detay sayfasi acilir ve denetim izi gorunur" do
    sign_in_as @manager_user
    @manager_expense.expense_events.create!(actor: "TravelBot", action: "submitted", reason: "API iletildi")

    get manager_expense_path(@manager_expense)
    assert_response :success
    assert_includes response.body, "Denetim Kaydı Zaman Çizelgesi"
    assert_includes response.body, "TRAVELBOT"
    assert_includes response.body, "API iletildi"
  end

  test "yeni harcama formu sayfasi goruntulenir" do
    sign_in_as @manager_user
    get new_manager_expense_path
    assert_response :success
    assert_includes response.body, "Canlı Harcama Gir ve Test Et"
  end

  test "yeni harcama formundan gonderilen harcama kaydedilir ve incelenir" do
    sign_in_as @manager_user
    assert_difference "Expense.count", 1 do
      post manager_expenses_path, params: {
        amount_try: "250.50",
        merchant: "Test Kitap Kırtasiye",
        category: "Ofis",
        description: "Ofis için not defteri ve kalemler",
        submitted_by: "hoca-canli-demo"
      }
    end

    created = Expense.order(created_at: :desc).first
    assert_equal 25050, created.amount_cents
    assert_equal "Test Kitap Kırtasiye", created.merchant
    assert_equal "hoca-canli-demo", created.submitted_by
  end
end
