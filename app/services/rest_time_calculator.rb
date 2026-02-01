class RestTimeCalculator
  BASE_REST = 60
  LARGE_MUSCLES = %w[legs back chest glutes].freeze

  def initialize(workout_set:, user:)
    @workout_set = workout_set
    @user = user
  end

  def recommended_seconds
    rest = BASE_REST
    rest += 30 if large_muscle_group?
    rest += 30 if heavy_lift?
    rest
  end

  private

  def large_muscle_group?
    @workout_set.exercise.muscle&.name&.in?(LARGE_MUSCLES)
  end

  def heavy_lift?
    last_rep = @workout_set.workout_reps.last
    return false unless last_rep&.weight&.positive?

    pr = @user.personal_records
      .where(exercise: @workout_set.exercise, pr_type: :max_weight)
      .maximum(:weight)

    return false unless pr&.positive?
    last_rep.weight >= (pr * 0.85)
  end
end
