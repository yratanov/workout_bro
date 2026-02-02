# frozen_string_literal: true

require "csv"

class WorkoutExporter
  HEADERS = %w[
    date
    workout_type
    exercise_name
    muscle_group
    set_number
    rep_number
    reps
    weight
    weight_unit
    band
    distance_meters
    time_seconds
    pace_per_km
    workout_notes
    set_notes
  ].freeze

  def initialize(user:)
    @user = user
  end

  def call
    CSV.generate do |csv|
      csv << HEADERS
      export_workouts(csv)
    end
  end

  private

  def export_workouts(csv)
    completed_workouts.each do |workout|
      if workout.strength?
        export_strength_workout(csv, workout)
      else
        export_run_workout(csv, workout)
      end
    end
  end

  def completed_workouts
    @user
      .workouts
      .where.not(ended_at: nil)
      .includes(workout_sets: [:workout_reps, { exercise: :muscle }])
      .order(started_at: :asc)
  end

  def export_strength_workout(csv, workout)
    set_number = 0

    workout.workout_sets.each do |workout_set|
      set_number += 1
      rep_number = 0

      workout_set.workout_reps.each do |rep|
        rep_number += 1
        csv << strength_row(workout, workout_set, set_number, rep_number, rep)
      end
    end
  end

  def export_run_workout(csv, workout)
    csv << run_row(workout)
  end

  def strength_row(workout, workout_set, set_number, rep_number, rep)
    [
      workout.date&.iso8601 || workout.started_at.to_date.iso8601,
      "strength",
      workout_set.exercise.name,
      workout_set.exercise.muscle&.name,
      set_number,
      rep_number,
      rep.reps,
      rep.weight,
      @user.weight_unit,
      rep.band,
      nil,
      nil,
      nil,
      workout.notes,
      workout_set.notes
    ]
  end

  def run_row(workout)
    [
      workout.date&.iso8601 || workout.started_at.to_date.iso8601,
      "run",
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      workout.distance,
      workout.time_in_seconds,
      format_pace(workout.pace),
      workout.notes,
      nil
    ]
  end

  def format_pace(pace_seconds)
    return nil unless pace_seconds

    minutes = (pace_seconds / 60).to_i
    seconds = (pace_seconds % 60).to_i
    format("%d:%02d", minutes, seconds)
  end
end
