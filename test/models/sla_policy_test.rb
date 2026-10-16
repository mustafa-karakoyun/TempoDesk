require "test_helper"

class SlaPolicyTest < ActiveSupport::TestCase
  test "due_at her oncelik icin dogru sureyi ekler" do
    from = Time.zone.local(2026, 10, 16, 12, 0, 0)

    assert_equal from + 4.hours,  SlaPolicy.due_at(priority: :urgent, from: from)
    assert_equal from + 8.hours,  SlaPolicy.due_at(priority: :high,   from: from)
    assert_equal from + 24.hours, SlaPolicy.due_at(priority: :normal, from: from)
    assert_equal from + 48.hours, SlaPolicy.due_at(priority: :low,    from: from)
  end

  test "due_at string oncelik kabul eder ve bilinmeyen oncelikte hata verir" do
    from = Time.zone.local(2026, 10, 16, 12, 0, 0)

    assert_equal from + 4.hours, SlaPolicy.due_at(priority: "urgent", from: from)
    assert_raises(KeyError) { SlaPolicy.due_at(priority: "bilinmeyen", from: from) }
  end

  test "from verilmezse simdiki zamani baz alir" do
    travel_to Time.zone.local(2026, 10, 16, 9, 30, 0) do
      assert_equal Time.zone.local(2026, 10, 16, 13, 30, 0), SlaPolicy.due_at(priority: :urgent)
    end
  end
end
