# == Schema Information
#
# Table name: personal_records
# Database name: primary
#
#  id             :integer          not null, primary key
#  achieved_on    :date             not null
#  band           :string
#  distance       :integer
#  pace           :float
#  pr_type        :integer          default("max_weight"), not null
#  reps           :integer
#  volume         :float
#  weight         :float
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  exercise_id    :integer
#  user_id        :integer          not null
#  workout_id     :integer          not null
#  workout_rep_id :integer
#
# Indexes
#
#  index_personal_records_on_exercise_id     (exercise_id)
#  index_personal_records_on_user_id         (user_id)
#  index_personal_records_on_workout_id      (workout_id)
#  index_personal_records_on_workout_rep_id  (workout_rep_id)
#  index_prs_on_user_exercise_type_band      (user_id,exercise_id,pr_type,band)
#
# Foreign Keys
#
#  exercise_id     (exercise_id => exercises.id) ON DELETE => cascade
#  user_id         (user_id => users.id)
#  workout_id      (workout_id => workouts.id) ON DELETE => cascade
#  workout_rep_id  (workout_rep_id => workout_reps.id) ON DELETE => cascade
#
describe PersonalRecord do
  fixtures :users,
           :exercises,
           :workouts,
           :workout_sets,
           :workout_reps,
           :personal_records

  let(:user) { users(:john) }
  let(:exercise) { exercises(:bench_press) }
  let(:workout) { workouts(:completed_workout) }
  let(:workout_rep) { workout_reps(:rep_one) }

  describe "associations" do
    it "belongs to user" do
      pr = personal_records(:bench_press_max_weight)
      expect(pr.user).to eq(users(:john))
    end

    it "belongs to exercise" do
      pr = personal_records(:bench_press_max_weight)
      expect(pr.exercise).to eq(exercises(:bench_press))
    end

    it "belongs to workout" do
      pr = personal_records(:bench_press_max_weight)
      expect(pr.workout).to eq(workouts(:completed_workout))
    end

    it "belongs to workout_rep" do
      pr = personal_records(:bench_press_max_weight)
      expect(pr.workout_rep).to eq(workout_reps(:rep_two))
    end
  end

  describe "validations" do
    it "is valid with valid strength PR attributes" do
      pr =
        PersonalRecord.new(
          user: user,
          exercise: exercise,
          workout: workout,
          workout_rep: workout_rep,
          pr_type: :max_weight,
          weight: 100,
          reps: 10,
          achieved_on: Date.today
        )
      expect(pr).to be_valid
    end

    it "is valid with valid run PR attributes" do
      run_workout =
        user.workouts.create!(
          workout_type: :run,
          started_at: 1.hour.ago,
          ended_at: Time.current,
          distance: 5000,
          time_in_seconds: 1800
        )
      pr =
        PersonalRecord.new(
          user: user,
          workout: run_workout,
          pr_type: :longest_distance,
          distance: 5000,
          achieved_on: Date.today
        )
      expect(pr).to be_valid
    end

    it "requires pr_type" do
      pr = PersonalRecord.new(pr_type: nil)
      expect(pr).not_to be_valid
      expect(pr.errors[:pr_type]).to be_present
    end

    it "requires reps for strength PRs" do
      pr = PersonalRecord.new(pr_type: :max_weight, reps: nil)
      expect(pr).not_to be_valid
      expect(pr.errors[:reps]).to be_present
    end

    it "requires positive reps for strength PRs" do
      pr = PersonalRecord.new(pr_type: :max_weight, reps: 0)
      expect(pr).not_to be_valid
      expect(pr.errors[:reps]).to be_present
    end

    it "does not require reps for run PRs" do
      run_workout =
        user.workouts.create!(
          workout_type: :run,
          started_at: 1.hour.ago,
          ended_at: Time.current,
          distance: 5000,
          time_in_seconds: 1800
        )
      pr =
        PersonalRecord.new(
          user: user,
          workout: run_workout,
          pr_type: :longest_distance,
          distance: 5000,
          achieved_on: Date.today
        )
      expect(pr).to be_valid
    end

    it "requires distance for run PRs" do
      pr = PersonalRecord.new(pr_type: :longest_distance, distance: nil)
      expect(pr).not_to be_valid
      expect(pr.errors[:distance]).to be_present
    end

    it "requires pace for fastest_pace PRs" do
      pr = PersonalRecord.new(pr_type: :fastest_pace, distance: 5000, pace: nil)
      expect(pr).not_to be_valid
      expect(pr.errors[:pace]).to be_present
    end

    it "requires achieved_on" do
      pr = PersonalRecord.new(achieved_on: nil)
      expect(pr).not_to be_valid
      expect(pr.errors[:achieved_on]).to be_present
    end

    it "validates band is in allowed values" do
      pr =
        PersonalRecord.new(
          user: user,
          exercise: exercise,
          workout: workout,
          workout_rep: workout_rep,
          pr_type: :max_weight,
          weight: 100,
          reps: 10,
          achieved_on: Date.today,
          band: "invalid_band"
        )
      expect(pr).not_to be_valid
      expect(pr.errors[:band]).to be_present
    end

    it "allows nil band" do
      pr =
        PersonalRecord.new(
          user: user,
          exercise: exercise,
          workout: workout,
          workout_rep: workout_rep,
          pr_type: :max_weight,
          weight: 100,
          reps: 10,
          achieved_on: Date.today,
          band: nil
        )
      expect(pr).to be_valid
    end

    it "allows valid band values" do
      WorkoutRep::BANDS.each do |band|
        pr =
          PersonalRecord.new(
            user: user,
            exercise: exercise,
            workout: workout,
            workout_rep: workout_rep,
            pr_type: :max_weight,
            weight: 100,
            reps: 10,
            achieved_on: Date.today,
            band: band
          )
        expect(pr).to be_valid
      end
    end
  end

  describe "enums" do
    it "defines pr_type enum" do
      expect(PersonalRecord.pr_types).to eq(
        "max_weight" => 0,
        "max_volume" => 1,
        "max_reps" => 2,
        "longest_distance" => 3,
        "fastest_pace" => 4
      )
    end

    it "allows max_weight type" do
      pr = personal_records(:bench_press_max_weight)
      expect(pr).to be_max_weight
    end

    it "allows max_volume type" do
      pr = personal_records(:bench_press_max_volume)
      expect(pr).to be_max_volume
    end

    it "allows longest_distance type" do
      run_workout =
        user.workouts.create!(
          workout_type: :run,
          started_at: 1.hour.ago,
          ended_at: Time.current,
          distance: 5000,
          time_in_seconds: 1800
        )
      pr =
        PersonalRecord.create!(
          user: user,
          workout: run_workout,
          pr_type: :longest_distance,
          distance: 5000,
          achieved_on: Date.today
        )
      expect(pr).to be_longest_distance
    end

    it "allows fastest_pace type" do
      run_workout =
        user.workouts.create!(
          workout_type: :run,
          started_at: 1.hour.ago,
          ended_at: Time.current,
          distance: 5000,
          time_in_seconds: 1800
        )
      pr =
        PersonalRecord.create!(
          user: user,
          workout: run_workout,
          pr_type: :fastest_pace,
          distance: 5000,
          pace: 6.0,
          achieved_on: Date.today
        )
      expect(pr).to be_fastest_pace
    end
  end

  describe "scopes" do
    it "orders by recent_first" do
      older_pr = personal_records(:bench_press_max_weight)
      newer_pr =
        PersonalRecord.create!(
          user: user,
          exercise: exercises(:squat),
          workout: workout,
          workout_rep: workout_rep,
          pr_type: :max_weight,
          weight: 150,
          reps: 5,
          achieved_on: Date.today
        )

      expect(PersonalRecord.recent_first.first).to eq(newer_pr)
    end

    it "includes exercise in timeline scope" do
      records = PersonalRecord.timeline
      expect(records.first.association(:exercise)).to be_loaded
    end
  end
end
