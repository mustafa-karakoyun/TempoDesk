module TicketsHelper
  # Sunucu tarafında üretilen SLA metni. JavaScript sayaç yok.
  #   çözülmüş, zamanında -> "SLA içinde çözüldü"
  #   çözülmüş, geç       -> "Geç çözüldü"            (artık açık bir ihlal yok, sönük etiket)
  #   açık, ihlalli       -> "5 sa 12 dk aşıldı"
  #   açık, süresi var    -> "3 sa 45 dk kaldı"
  def sla_label(ticket)
    if ticket.resolved?
      return ticket.sla_breached? ? "Geç çözüldü" : "SLA içinde çözüldü"
    end

    if ticket.sla_breached?
      "#{sla_duration_text(-ticket.sla_seconds_remaining)} aşıldı"
    else
      "#{sla_duration_text(ticket.sla_seconds_remaining)} kaldı"
    end
  end

  def sla_badge_class(ticket)
    if ticket.resolved?
      ticket.sla_breached? ? "badge-late" : "badge-resolved"
    elsif ticket.sla_breached?
      "badge-breached"
    else
      "badge-active"
    end
  end

  # Saniyeyi "1 dk'dan az", "45 dk" veya "3 sa 59 dk" biçiminde yazar.
  def sla_duration_text(seconds)
    total_minutes = seconds / 60
    hours, minutes = total_minutes.divmod(60)

    if total_minutes.zero?
      "1 dk'dan az"
    elsif hours.zero?
      "#{minutes} dk"
    else
      "#{hours} sa #{minutes} dk"
    end
  end

  def priority_label(priority)
    case priority.to_s
    when "low"    then "Düşük"
    when "normal" then "Normal"
    when "high"   then "Yüksek"
    when "urgent" then "Acil"
    else priority.to_s.humanize
    end
  end

  def priority_badge_class(priority)
    case priority.to_s
    when "urgent" then "badge-priority-urgent"
    when "high"   then "badge-priority-high"
    when "normal" then "badge-priority-normal"
    when "low"    then "badge-priority-low"
    else "badge-secondary"
    end
  end

  def status_label(status)
    case status.to_s
    when "new"    then "Yeni"
    when "open"   then "Açık"
    when "solved" then "Çözüldü"
    when "closed" then "Kapatıldı"
    else status.to_s.humanize
    end
  end

  def status_badge_class(status)
    case status.to_s
    when "new"    then "badge-status-new"
    when "open"   then "badge-status-open"
    when "solved" then "badge-status-solved"
    when "closed" then "badge-status-closed"
    else "badge-secondary"
    end
  end
end
