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

  def memory_category_icon(category)
    CATEGORY_ICONS[category] || "info"
  end
end
