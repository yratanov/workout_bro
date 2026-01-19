module ApplicationHelper
  include FormHelpers
  include InlineSvg::ActionView::Helpers

  include ComponentsShorthand

  components :button, :badge, :modal

  def icon(name, size: "w-4 h-4", **options)
    classes = "#{size} text-current #{options.delete(:class)}".strip
    inline_svg_tag("icons/#{name}.svg", class: classes, **options)
  end

  MUSCLE_ICONS = %w[chest back shoulders biceps triceps legs glutes core].freeze

  def muscle_icon(muscle, size: "w-4 h-4", **options)
    return nil if muscle.blank?

    muscle_name = muscle.is_a?(Muscle) ? muscle.name : muscle.to_s.downcase
    return nil unless MUSCLE_ICONS.include?(muscle_name)

    icon("muscles/#{muscle_name}", size: size, **options)
  end

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
