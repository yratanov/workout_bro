class RestTimeCalculator
  BASE_REST = 60
  LARGE_MUSCLES = %w[legs back chest glutes].freeze

  def initialize(workout_set:, user:)
    @workout_set = workout_set
    @user = user
  end

  def recommended_seconds
    routine_rest = matching_routine_day_exercise&.max_rest
    return routine_rest if routine_rest.present?

    rest = BASE_REST
    rest += 30 if large_muscle_group?
    rest += 30 if heavy_lift?
    rest
  end

  private

  def matching_routine_day_exercise
    @workout_set
      .workout
      .workout_routine_day
      &.workout_routine_day_exercises
      &.find_by(
      if @workout_set.superset_id?
        { superset_id: @workout_set.superset_id }
      else
        { exercise_id: @workout_set.exercise_id }
      end
    )
  end

  def large_muscle_group?
    @workout_set.exercise.muscle&.name&.in?(LARGE_MUSCLES)
  end

  def heavy_lift?
    last_rep = @workout_set.workout_reps.last
    return false unless last_rep&.weight&.positive?

    pr =
      @user
        .personal_records
        .where(exercise: @workout_set.exercise, pr_type: :max_weight)
        .maximum(:weight)

    return false unless pr&.positive?
    last_rep.weight >= (pr * 0.85)
  end
end
