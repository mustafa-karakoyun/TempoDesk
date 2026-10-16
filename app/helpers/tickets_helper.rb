module TicketsHelper
  # Sunucu tarafında üretilen SLA metni. JavaScript sayaç yok.
  #   ihlal           -> "SLA aşıldı"
  #   zamanında çözüm -> "SLA içinde çözüldü"
  #   açık bilet      -> "3 sa 59 dk kaldı"
  def sla_label(ticket)
    return "SLA aşıldı" if ticket.sla_breached?
    return "SLA içinde çözüldü" if ticket.resolved?

    total_minutes = ticket.sla_seconds_remaining / 60
    hours, minutes = total_minutes.divmod(60)

    if total_minutes.zero?
      "1 dk'dan az kaldı"
    elsif hours.zero?
      "#{minutes} dk kaldı"
    else
      "#{hours} sa #{minutes} dk kaldı"
    end
  end

  def sla_badge_class(ticket)
    if ticket.sla_breached?
      "badge-breached"
    elsif ticket.resolved?
      "badge-resolved"
    else
      "badge-active"
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
