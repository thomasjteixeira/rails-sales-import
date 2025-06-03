module ApplicationHelper
  def status_badge_class(status)
    case status.to_s
    when "completed"
      "badge-success"
    when "failed"
      "badge-error"
    when "pending"
      "badge-warning"
    else
      "badge-neutral"
    end
  end

  def format_currency(cents)
    return "R$ 0,00" if cents.nil? || cents == 0

    number_to_currency(
      (cents / 100.0),
      unit: "R$",
      separator: ",",
      delimiter: ".",
      format: "%u %n"
    )
  end

  def format_datetime(datetime)
    return "N/A" if datetime.nil?

    datetime.strftime("%d/%m/%Y %H:%M")
  end
end
