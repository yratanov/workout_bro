module WorkoutsHelper
  def modal_title(workout)
    date = workout.created_at.strftime("%d %b %Y")
    if workout.run?
      "Run · #{date}"
    else
      "#{workout.workout_routine_day&.name || "Strength"} · #{date}"
    end
  end

  def run_pace(workout)
    return unless workout.run?

    started_at = workout.started_at
    ended_at = workout.ended_at

    return unless started_at && ended_at

    total_seconds = ended_at - started_at

    distance = workout.distance
    return unless distance && distance > 0

    pace_seconds = total_seconds / (distance / 1000.0) # pace in seconds per km
    minutes = (pace_seconds / 60).floor
    seconds = (pace_seconds % 60).round
    format("%d:%02d min/km", minutes, seconds)
  end

  def format_volume(volume, unit = "kg")
    return "0#{unit}" if volume.nil? || volume.zero?

    if volume >= 1000
      tonnes = (volume / 1000.0).round(1)
      # Remove trailing .0 for whole numbers
      tonnes = tonnes.to_i if tonnes == tonnes.to_i
      "#{tonnes}t"
    else
      volume_display = volume.to_i == volume ? volume.to_i : volume.round(1)
      "#{volume_display}#{unit}"
    end
  end

  def comparison_class(diff)
    if diff.nil? || diff.zero?
      "text-slate-400"
    elsif diff > 0
      "text-green-400"
    else
      "text-red-400"
    end
  end

  def comparison_arrow(diff)
    if diff.nil? || diff.zero?
      "minus"
    elsif diff > 0
      "chevron_up"
    else
      "chevron_down"
    end
  end

  def format_pace(pace_seconds)
    return nil unless pace_seconds&.positive?

    minutes = (pace_seconds / 60).floor
    seconds = (pace_seconds % 60).round
    format("%d:%02d", minutes, seconds)
  end

  def format_pace_diff(diff_seconds)
    return nil unless diff_seconds

    abs_diff = diff_seconds.abs
    minutes = (abs_diff / 60).floor
    seconds = (abs_diff % 60).round

    if minutes > 0
      format("%d:%02d", minutes, seconds)
    else
      "#{seconds}s"
    end
  end

  def pr_type_label(pr_type)
    I18n.t("workouts.summary.pr_types.#{pr_type}")
  end
end
