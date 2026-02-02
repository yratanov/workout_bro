class PersonalRecordDetector
  def initialize(workout:)
    @workout = workout
    @user = workout.user
    @new_prs = []
    @best_candidates = {}
  end

  def call
    return @new_prs unless @workout.ended?

    @workout.personal_records.destroy_all

    if @workout.strength?
      collect_best_candidates
      create_prs_for_improvements
    elsif @workout.run?
      detect_run_prs
    end

    @new_prs
  end

  private

  def collect_best_candidates
    @workout
      .workout_sets
      .includes(:exercise, :workout_reps)
      .find_each do |workout_set|
        exercise = workout_set.exercise
        workout_set.workout_reps.each do |rep|
          collect_candidates_for_rep(rep, exercise)
        end
      end
  end

  def collect_candidates_for_rep(rep, exercise)
    if exercise.with_weights
      collect_max_weight_candidate(rep, exercise)
      if rep.weight.to_f > 0 && rep.reps > 0
        collect_max_volume_candidate(rep, exercise)
      end
    else
      collect_max_reps_candidate(rep, exercise)
    end
  end

  def collect_max_weight_candidate(rep, exercise)
    return unless rep.weight.to_f > 0

    key = candidate_key(exercise, :max_weight, rep.band)
    current = @best_candidates[key]

    if current.nil? || rep.weight > current[:value]
      @best_candidates[key] = {
        rep: rep,
        exercise: exercise,
        pr_type: :max_weight,
        value: rep.weight,
        weight: rep.weight,
        reps: rep.reps,
        volume: nil,
        band: rep.band
      }
    end
  end

  def collect_max_volume_candidate(rep, exercise)
    volume = rep.weight.to_f * rep.reps
    return unless volume > 0

    key = candidate_key(exercise, :max_volume, rep.band)
    current = @best_candidates[key]

    if current.nil? || volume > current[:value]
      @best_candidates[key] = {
        rep: rep,
        exercise: exercise,
        pr_type: :max_volume,
        value: volume,
        weight: rep.weight,
        reps: rep.reps,
        volume: volume,
        band: rep.band
      }
    end
  end

  def collect_max_reps_candidate(rep, exercise)
    key = candidate_key(exercise, :max_reps, rep.band)
    current = @best_candidates[key]

    if current.nil? || rep.reps > current[:value]
      @best_candidates[key] = {
        rep: rep,
        exercise: exercise,
        pr_type: :max_reps,
        value: rep.reps,
        weight: nil,
        reps: rep.reps,
        volume: nil,
        band: rep.band
      }
    end
  end

  def candidate_key(exercise, pr_type, band)
    [exercise.id, pr_type, band]
  end

  def create_prs_for_improvements
    @best_candidates.each_value do |candidate|
      existing_pr =
        find_existing_pr(
          candidate[:exercise],
          candidate[:pr_type],
          candidate[:band]
        )

      create_pr(candidate) if beats_existing_pr?(candidate, existing_pr)
    end
  end

  def find_existing_pr(exercise, pr_type, band)
    scope =
      @user
        .personal_records
        .where(exercise: exercise, pr_type: pr_type, band: band)
        .where.not(workout: @workout)

    case pr_type
    when :max_weight
      scope.order(weight: :desc).first
    when :max_volume
      scope.order(volume: :desc).first
    when :max_reps
      scope.order(reps: :desc).first
    else
      scope.first
    end
  end

  def beats_existing_pr?(candidate, existing_pr)
    return true if existing_pr.nil?

    case candidate[:pr_type]
    when :max_weight
      candidate[:weight] > existing_pr.weight
    when :max_volume
      candidate[:volume] > existing_pr.volume
    when :max_reps
      candidate[:reps] > existing_pr.reps
    end
  end

  def create_pr(candidate)
    pr =
      @user.personal_records.create!(
        exercise: candidate[:exercise],
        workout_rep: candidate[:rep],
        workout: @workout,
        pr_type: candidate[:pr_type],
        weight: candidate[:weight],
        reps: candidate[:reps],
        volume: candidate[:volume],
        band: candidate[:band],
        achieved_on: @workout.started_at.to_date
      )
    @new_prs << pr
  end

  # Run PR detection
  def detect_run_prs
    return unless @workout.distance&.positive?

    detect_longest_distance_pr
    detect_fastest_pace_pr
  end

  def detect_longest_distance_pr
    existing_pr =
      @user
        .personal_records
        .where(pr_type: :longest_distance)
        .where.not(workout: @workout)
        .order(distance: :desc)
        .first

    if existing_pr.nil? || @workout.distance > existing_pr.distance
      pr =
        @user.personal_records.create!(
          workout: @workout,
          pr_type: :longest_distance,
          distance: @workout.distance,
          achieved_on: @workout.started_at.to_date
        )
      @new_prs << pr
    end
  end

  def detect_fastest_pace_pr
    current_pace = @workout.pace
    return unless current_pace

    existing_pr =
      @user
        .personal_records
        .where(pr_type: :fastest_pace)
        .where.not(workout: @workout)
        .order(pace: :asc)
        .first

    if existing_pr.nil? || current_pace < existing_pr.pace
      pr =
        @user.personal_records.create!(
          workout: @workout,
          pr_type: :fastest_pace,
          distance: @workout.distance,
          pace: current_pace,
          achieved_on: @workout.started_at.to_date
        )
      @new_prs << pr
    end
  end
end
