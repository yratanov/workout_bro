module ApplicationHelper
  include ComponentsShorthand
  
  components :button, :badge, :modal, :icon_xmark, :icon_stopwatch, :icon_exit, :icon_chevron_down

  def seconds_to_human(seconds)
    return 0 if seconds.nil? || seconds < 0

    return "0s" if seconds == 0

    parts = []
    minutes, seconds = seconds.divmod(60)
    hours, minutes = minutes.divmod(60)

    parts << "#{hours}h" if hours > 0
    parts << "#{minutes}m" if minutes > 0
    parts << "#{seconds}s" if seconds > 0

    parts.join(" ")
  end
end
