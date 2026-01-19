module WorkoutsHelper
  def modal_title(workout)
    date = workout.created_at.strftime("%d %b %Y")
    if workout.run?
      "Run · #{date}"
    else
      "#{workout.workout_routine_day&.name || 'Strength'} · #{date}"
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
end
