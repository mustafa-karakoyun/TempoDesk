class SlaPolicy
  # SLA süre kuralının yaşadığı TEK yer. Başka hiçbir dosyada süre sabiti yazılmaz.
  # Hafta sonu / mesai saati gibi bir değişiklik gerekirse yalnızca `due_at` değişir.
  DURATIONS = {
    "urgent" => 4.hours,
    "high"   => 8.hours,
    "normal" => 24.hours,
    "low"    => 48.hours
  }.freeze

  def self.due_at(priority:, from: Time.current)
    from + DURATIONS.fetch(priority.to_s)
  end
end
