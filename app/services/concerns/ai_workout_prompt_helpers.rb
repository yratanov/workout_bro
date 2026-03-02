# frozen_string_literal: true

module AiWorkoutPromptHelpers
  extend ActiveSupport::Concern

  private

  def format_duration(seconds)
    return "N/A" unless seconds&.positive?

    minutes = seconds / 60
    remaining = seconds % 60
    "#{minutes}m #{remaining}s"
  end

  def format_pace(pace)
    return "N/A" unless pace&.positive?

    minutes = (pace / 60).to_i
    seconds = (pace % 60).to_i
    "#{minutes}:#{seconds.to_s.rjust(2, "0")} min/km"
  end

  def set_duration(workout_set)
    return nil unless workout_set.started_at && workout_set.ended_at

    elapsed = (workout_set.ended_at - workout_set.started_at).to_i
    elapsed - (workout_set.total_paused_seconds || 0)
  end

  def preload_previous_sets(workout_sets, user)
    exercise_ids = workout_sets.map(&:exercise_id).uniq
    set_ids = workout_sets.map(&:id)

    all_previous =
      user
        .workout_sets
        .where(exercise_id: exercise_ids)
        .where.not(id: set_ids)
        .where.not(ended_at: nil)
        .includes(:workout_reps)
        .order(created_at: :desc)

    all_previous
      .group_by(&:exercise_id)
      .transform_values { |sets| sets.first(2) }
  end

  def format_workout_exercises(workout_sets, user)
    sets = workout_sets.includes(:exercise, :workout_reps)
    previous_sets_cache = preload_previous_sets(sets, user)
    lines = []

    grouped = sets.group_by { |ws| ws.superset_group }
    standalone = grouped.delete(nil) || []

    standalone.each do |ws|
      lines.concat(
        format_single_set(ws, user, previous_sets_cache: previous_sets_cache)
      )
    end

    grouped.each_value do |superset_sets|
      names = superset_sets.map { |ws| ws.exercise.name }.uniq.join(" + ")
      lines << "- Superset: #{names}"
      superset_sets.each do |ws|
        lines.concat(
          format_single_set(
            ws,
            user,
            indent: "  ",
            previous_sets_cache: previous_sets_cache
          )
        )
      end
    end

    lines
  end

  def format_single_set(ws, user, indent: "", previous_sets_cache: nil)
    lines = []
    reps_info =
      ws.workout_reps.map { |r| "#{r.weight}kg x #{r.reps}" }.join(", ")
    return lines if reps_info.blank?

    set_line = "#{indent}- #{ws.exercise.name}: #{reps_info}"
    duration = set_duration(ws)
    set_line += " (#{format_duration(duration)})" if duration
    lines << set_line
    lines << "#{indent}  Notes: #{ws.notes}" if ws.notes.present?

    format_previous_sets_info(
      ws,
      user,
      previous_sets_cache: previous_sets_cache
    ).each { |prev_line| lines << "#{indent}  #{prev_line}" }

    lines
  end

  def format_previous_sets_info(workout_set, user, previous_sets_cache: nil)
    previous_sets =
      if previous_sets_cache
        previous_sets_cache[workout_set.exercise_id] || []
      else
        user
          .workout_sets
          .where(exercise: workout_set.exercise)
          .where.not(id: workout_set.id)
          .where.not(ended_at: nil)
          .includes(:workout_reps)
          .order(created_at: :desc)
          .limit(2)
      end

    previous_sets.each_with_index.filter_map do |prev_set, i|
      reps =
        prev_set.workout_reps.map { |r| "#{r.weight}kg x #{r.reps}" }.join(", ")
      next if reps.blank?

      date = prev_set.created_at.strftime("%-d %b")
      label = i.zero? ? "Previous (#{date})" : "2 sessions ago (#{date})"
      "#{label}: #{reps}"
    end
  end

  def format_run_summary(workout)
    summary = WorkoutSummaryCalculator.new(workout: workout).call
    lines = []
    lines << "Type: Run"
    lines << "Distance: #{(workout.distance.to_f / 1000).round(2)}km"
    lines << "Duration: #{format_duration(summary.duration)}"
    lines << "Pace: #{format_pace(summary.pace)}" if summary.pace
    if workout.avg_heart_rate
      lines << "Avg Heart Rate: #{workout.avg_heart_rate} bpm"
    end
    if workout.max_heart_rate
      lines << "Max Heart Rate: #{workout.max_heart_rate} bpm"
    end
    lines << "Avg Cadence: #{workout.avg_cadence} spm" if workout.avg_cadence
    if workout.elevation_gain
      lines << "Elevation Gain: #{workout.elevation_gain.round(1)}m"
    end
    lines << "VO2max: #{workout.vo2max.round(1)}" if workout.vo2max
    lines << "Notes: #{workout.notes}" if workout.notes.present?

    if summary.comparison&.pace_diff
      lines << "Pace change vs last time: #{summary.comparison.pace_diff.round(1)}s/km"
    end

    lines.join("\n")
  end
end
