class WorkoutSummaryCalculator
  Result =
    Struct.new(
      :total_volume,
      :total_sets,
      :total_reps,
      :duration,
      :muscles_worked,
      :previous_workout,
      :comparison,
      :new_prs,
      :distance,
      :pace,
      keyword_init: true
    )

  Comparison =
    Struct.new(
      :volume_diff,
      :volume_diff_percent,
      :pace_diff,
      keyword_init: true
    )

  def initialize(workout:, new_prs: [])
    @workout = workout
    @user = workout.user
    @new_prs = new_prs
  end

  def call
    @workout.run? ? calculate_run_summary : calculate_strength_summary
  end

  private

  def calculate_strength_summary
    muscles = calculate_muscles_worked
    previous = find_previous_workout
    comparison = calculate_comparison(previous) if previous

    Result.new(
      total_volume: calculate_total_volume,
      total_sets: @workout.workout_sets.count,
      total_reps: calculate_total_reps,
      duration: @workout.time_in_seconds,
      muscles_worked: muscles,
      previous_workout: previous,
      comparison: comparison,
      new_prs: @new_prs
    )
  end

  def calculate_run_summary
    previous = find_previous_run
    comparison = calculate_run_comparison(previous) if previous

    Result.new(
      distance: @workout.distance,
      duration: @workout.time_in_seconds,
      pace: calculate_pace,
      previous_workout: previous,
      comparison: comparison,
      new_prs: @new_prs
    )
  end

  def calculate_total_volume
    @workout
      .workout_sets
      .joins(:workout_reps)
      .sum("COALESCE(workout_reps.weight, 0) * workout_reps.reps")
  end

  def calculate_total_reps
    @workout.workout_sets.joins(:workout_reps).sum("workout_reps.reps")
  end

  def calculate_muscles_worked
    @workout
      .workout_sets
      .includes(exercise: :muscle)
      .flat_map { |set| set.exercise.muscle }
      .compact
      .uniq
  end

  def find_previous_workout
    # First try to find by workout_routine_day_id
    if @workout.workout_routine_day_id.present?
      previous =
        @user
          .workouts
          .where(workout_routine_day_id: @workout.workout_routine_day_id)
          .where.not(id: @workout.id)
          .where.not(ended_at: nil)
          .where("started_at < ?", @workout.started_at)
          .order(started_at: :desc)
          .first
      return previous if previous
    end

    # Fallback: find by exercise overlap (≥50% overlap)
    find_by_exercise_overlap
  end

  def find_by_exercise_overlap
    current_exercise_ids = @workout.workout_sets.pluck(:exercise_id).uniq
    return nil if current_exercise_ids.empty?

    # Get all previous completed strength workouts
    previous_workouts =
      @user
        .workouts
        .where(workout_type: :strength)
        .where.not(id: @workout.id)
        .where.not(ended_at: nil)
        .where("started_at < ?", @workout.started_at)
        .includes(:workout_sets)
        .order(started_at: :desc)
        .limit(20)

    previous_workouts.find do |prev|
      prev_exercise_ids = prev.workout_sets.pluck(:exercise_id).uniq
      next false if prev_exercise_ids.empty?

      overlap = (current_exercise_ids & prev_exercise_ids).size
      overlap_percent = overlap.to_f / current_exercise_ids.size
      overlap_percent >= 0.5
    end
  end

  def calculate_comparison(previous)
    prev_volume = calculate_volume_for(previous)
    current_volume = calculate_total_volume

    volume_diff = current_volume - prev_volume
    volume_diff_percent =
      prev_volume > 0 ? ((volume_diff.to_f / prev_volume) * 100).round(1) : 0

    Comparison.new(
      volume_diff: volume_diff,
      volume_diff_percent: volume_diff_percent
    )
  end

  def calculate_volume_for(workout)
    workout
      .workout_sets
      .joins(:workout_reps)
      .sum("COALESCE(workout_reps.weight, 0) * workout_reps.reps")
  end

  def find_previous_run
    @user
      .workouts
      .where(workout_type: :run)
      .where.not(id: @workout.id)
      .where.not(ended_at: nil)
      .where("started_at < ?", @workout.started_at)
      .order(started_at: :desc)
      .first
  end

  def calculate_pace
    unless @workout.distance&.positive? && @workout.time_in_seconds&.positive?
      return nil
    end

    @workout.time_in_seconds.to_f / (@workout.distance / 1000.0)
  end

  def calculate_run_comparison(previous)
    prev_pace = calculate_pace_for(previous)
    current_pace = calculate_pace

    return nil unless prev_pace && current_pace

    pace_diff = prev_pace - current_pace # Negative means faster (improvement)

    Comparison.new(pace_diff: pace_diff.round(1))
  end

  def calculate_pace_for(workout)
    unless workout.distance&.positive? && workout.time_in_seconds&.positive?
      return nil
    end

    workout.time_in_seconds.to_f / (workout.distance / 1000.0)
  end
end
