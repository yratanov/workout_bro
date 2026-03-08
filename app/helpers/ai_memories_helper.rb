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
    { min: 1, max: 3, bars: 1, color: "#94a3b8", label_key: "low" },
    { min: 4, max: 5, bars: 2, color: "#60a5fa", label_key: "medium" },
    { min: 6, max: 7, bars: 3, color: "#fbbf24", label_key: "high" },
    { min: 8, max: 10, bars: 4, color: "#f87171", label_key: "critical" }
  ].freeze

  def memory_category_icon(category)
    CATEGORY_ICONS[category] || "info"
  end

  def importance_level(importance)
    IMPORTANCE_LEVELS.find { |l| importance.between?(l[:min], l[:max]) } ||
      IMPORTANCE_LEVELS.last
  end

  BAR_HEIGHTS = [5, 9, 13, 17].freeze
  BAR_WIDTH = 4

  INACTIVE_COLOR = "rgba(100, 116, 139, 0.4)"

  def importance_bars(importance)
    level = importance_level(importance)
    bars =
      BAR_HEIGHTS.each_with_index.map do |height, i|
        active = i < level[:bars]
        bg = active ? level[:color] : INACTIVE_COLOR
        tag.span(
          class: "inline-block rounded-sm",
          style: "width: #{BAR_WIDTH}px; height: #{height}px; background: #{bg}"
        )
      end
    tag.span(
      safe_join(bars),
      class: "inline-flex items-end",
      style: "gap: 2px",
      title: t("ai_memories.index.importance_levels.#{level[:label_key]}")
    )
  end
end
