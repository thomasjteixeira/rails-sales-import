module DashboardHelper
  def status_badge_class(status)
    case status.to_s
    when "completed"
      "badge-success"
    when "processing"
      "badge-info"
    when "failed"
      "badge-error"
    when "pending"
      "badge-warning"
    else
      "badge-neutral"
    end
  end
end
