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
end
