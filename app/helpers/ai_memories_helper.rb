# frozen_string_literal: true

module AiMemoriesHelper
  CATEGORY_ICONS = {
    "schedule" => "calendar",
    "equipment" => "dumbbell",
    "health" => "heart",
    "preferences" => "settings",
    "progress" => "trending-up",
    "behavior" => "activity",
    "goals" => "target"
  }.freeze

  IMPORTANCE_LEVELS = [
    { min: 1, max: 3, bars: 1, color: "text-slate-400", label_key: "low" },
    { min: 4, max: 5, bars: 2, color: "text-blue-400", label_key: "medium" },
    { min: 6, max: 7, bars: 3, color: "text-amber-400", label_key: "high" },
    { min: 8, max: 10, bars: 4, color: "text-red-400", label_key: "critical" }
  ].freeze

  def memory_category_icon(category)
    CATEGORY_ICONS[category] || "info"
  end

  def importance_level(importance)
    IMPORTANCE_LEVELS.find { |l| importance.between?(l[:min], l[:max]) } ||
      IMPORTANCE_LEVELS.last
  end

  def importance_bars(importance)
    level = importance_level(importance)
    bars =
      4.times.map do |i|
        active = i < level[:bars]
        height = 6 + (i * 4) # 6, 10, 14, 18px
        color = active ? level[:color].sub("text-", "bg-") : "bg-slate-600"
        tag.span(
          class: "inline-block w-1 rounded-full #{color}",
          style: "height: #{height}px"
        )
      end
    tag.span(
      safe_join(bars),
      class: "inline-flex items-end gap-0.5",
      title: t("ai_memories.index.importance_levels.#{level[:label_key]}")
    )
  end
end
