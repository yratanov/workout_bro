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

  def format_workout_exercises(workout_sets, user)
    sets = workout_sets.includes(:exercise, :workout_reps)
    lines = []

    grouped = sets.group_by { |ws| ws.superset_group }
    standalone = grouped.delete(nil) || []

    standalone.each { |ws| lines.concat(format_single_set(ws, user)) }

    grouped.each_value do |superset_sets|
      names = superset_sets.map { |ws| ws.exercise.name }.uniq.join(" + ")
      lines << "- Superset: #{names}"
      superset_sets.each do |ws|
        lines.concat(format_single_set(ws, user, indent: "  "))
      end
    end

    lines
  end

  def format_single_set(workout_set, user, indent: "")
    lines = []
    reps_info =
      workout_set
        .workout_reps
        .map { |r| "#{r.weight}kg x #{r.reps}" }
        .join(", ")
    return lines if reps_info.blank?

    set_line = "#{indent}- #{workout_set.exercise.name}: #{reps_info}"
    duration = set_duration(workout_set)
    set_line += " (#{format_duration(duration)})" if duration
    lines << set_line
    if workout_set.notes.present?
      lines << "#{indent}  Notes: #{workout_set.notes}"
    end

    format_previous_sets_info(workout_set, user).each do |prev_line|
      lines << "#{indent}  #{prev_line}"
    end

    lines
  end

  def format_previous_sets_info(workout_set, user)
    previous_sets =
      user
        .workout_sets
        .where(exercise: workout_set.exercise)
        .where.not(id: workout_set.id)
        .where.not(ended_at: nil)
        .includes(:workout_reps)
        .order(created_at: :desc)
        .limit(2)

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
    lines << "Notes: #{workout.notes}" if workout.notes.present?

    if summary.comparison&.pace_diff
      lines << "Pace change vs last time: #{summary.comparison.pace_diff.round(1)}s/km"
    end

    lines.join("\n")
  end
end
