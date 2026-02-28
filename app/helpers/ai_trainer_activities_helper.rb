# frozen_string_literal: true

module AiTrainerActivitiesHelper
  def activity_type_label(activity)
    t("ai_trainer_activities.types.#{activity.activity_type}")
  end

  def activity_icon(activity)
    case activity.activity_type
    when "full_review"
      "sparkles"
    when "workout_review"
      "dumbbell"
    when "weekly_report"
      "chart"
    end
  end

  def activity_color_class(activity)
    case activity.activity_type
    when "full_review"
      "text-green-400"
    when "workout_review"
      "text-blue-400"
    when "weekly_report"
      "text-purple-400"
    end
  end

  def activity_dot_class(activity)
    case activity.activity_type
    when "full_review"
      "bg-green-400"
    when "workout_review"
      "bg-blue-400"
    when "weekly_report"
      "bg-purple-400"
    end
  end
end
