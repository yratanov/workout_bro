# == Schema Information
#
# Table name: workout_sets
# Database name: primary
#
#  id                   :integer          not null, primary key
#  ended_at             :datetime
#  notes                :text
#  paused_at            :datetime
#  started_at           :datetime
#  superset_group       :integer
#  total_paused_seconds :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  exercise_id          :integer          not null
#  superset_id          :integer
#  workout_id           :integer          not null
#
# Indexes
#
#  index_workout_sets_on_exercise_id                    (exercise_id)
#  index_workout_sets_on_superset_id                    (superset_id)
#  index_workout_sets_on_workout_id                     (workout_id)
#  index_workout_sets_on_workout_id_and_superset_group  (workout_id,superset_group)
#
# Foreign Keys
#
#  exercise_id  (exercise_id => exercises.id) ON DELETE => restrict
#  superset_id  (superset_id => supersets.id)
#  workout_id   (workout_id => workouts.id)
#
describe WorkoutSet do
  fixtures :users,
           :workouts,
           :exercises,
           :workout_sets,
           :workout_reps,
           :supersets

  describe "#default_rep_values" do
    let(:user) { users(:john) }
    let(:exercise) { exercises(:bench_press) }

    context "when previous workout has a rep at the same index" do
      it "returns values from the previous workout rep at the same index" do
        # Create a completed workout with reps
        old_workout =
          Workout.create!(
            user: user,
            workout_type: "strength",
            started_at: 2.days.ago,
            ended_at: 2.days.ago + 1.hour
          )
        old_set =
          WorkoutSet.create!(
            workout: old_workout,
            exercise: exercise,
            started_at: 2.days.ago,
            ended_at: 2.days.ago + 10.minutes
          )
        old_set.workout_reps.create!(reps: 12, weight: 80, band: "heavy")
        old_set.workout_reps.create!(reps: 10, weight: 85, band: "medium")

        # Create current workout set with one rep already
        current_workout =
          Workout.create!(
            user: user,
            workout_type: "strength",
            started_at: 1.hour.ago
          )
        current_set =
          WorkoutSet.create!(
            workout: current_workout,
            exercise: exercise,
            started_at: 1.hour.ago
          )
        current_set.workout_reps.create!(reps: 15, weight: 70, band: nil)

        # Should get values from old_set's second rep (index 1)
        defaults = current_set.default_rep_values
        expect(defaults[:reps]).to eq(10)
        expect(defaults[:weight]).to eq(85)
        expect(defaults[:band]).to eq("medium")
      end
    end

    context "when previous workout has no rep at the same index but current set has reps" do
      it "returns values from the last rep in current set" do
        # Create a completed workout with only one rep
        old_workout =
          Workout.create!(
            user: user,
            workout_type: "strength",
            started_at: 2.days.ago,
            ended_at: 2.days.ago + 1.hour
          )
        old_set =
          WorkoutSet.create!(
            workout: old_workout,
            exercise: exercise,
            started_at: 2.days.ago,
            ended_at: 2.days.ago + 10.minutes
          )
        old_set.workout_reps.create!(reps: 12, weight: 80, band: nil)

        # Create current workout set with two reps already (so index 2 won't exist in old_set)
        current_workout =
          Workout.create!(
            user: user,
            workout_type: "strength",
            started_at: 1.hour.ago
          )
        current_set =
          WorkoutSet.create!(
            workout: current_workout,
            exercise: exercise,
            started_at: 1.hour.ago
          )
        current_set.workout_reps.create!(reps: 15, weight: 70, band: nil)
        current_set.workout_reps.create!(reps: 14, weight: 75, band: "light")

        # Should get values from current_set's last rep
        defaults = current_set.default_rep_values
        expect(defaults[:reps]).to eq(14)
        expect(defaults[:weight]).to eq(75)
        expect(defaults[:band]).to eq("light")
      end
    end

    context "when there are no previous reps anywhere" do
      it "returns default values" do
        # Create a new exercise with no history
        new_exercise = Exercise.create!(name: "New Exercise", user: user)

        current_workout =
          Workout.create!(
            user: user,
            workout_type: "strength",
            started_at: 1.hour.ago
          )
        current_set =
          WorkoutSet.create!(
            workout: current_workout,
            exercise: new_exercise,
            started_at: 1.hour.ago
          )

        defaults = current_set.default_rep_values
        expect(defaults[:reps]).to eq(10)
        expect(defaults[:weight]).to eq(10)
        expect(defaults[:band]).to be_nil
      end
    end
  end

  describe "#in_superset?" do
    let(:user) { users(:john) }
    let(:workout) do
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 1.hour.ago
      )
    end

    it "returns true when has both superset_id and superset_group" do
      set =
        WorkoutSet.new(
          workout: workout,
          exercise: exercises(:bench_press),
          superset: supersets(:push_pull),
          superset_group: 1
        )
      expect(set.in_superset?).to be true
    end

    it "returns false when only has superset_id" do
      set =
        WorkoutSet.new(
          workout: workout,
          exercise: exercises(:bench_press),
          superset: supersets(:push_pull)
        )
      expect(set.in_superset?).to be false
    end

    it "returns false when only has superset_group" do
      set =
        WorkoutSet.new(
          workout: workout,
          exercise: exercises(:bench_press),
          superset_group: 1
        )
      expect(set.in_superset?).to be false
    end

    it "returns false when has neither" do
      set = WorkoutSet.new(workout: workout, exercise: exercises(:bench_press))
      expect(set.in_superset?).to be false
    end
  end

  describe "#superset_sibling_sets" do
    let(:user) { users(:john) }
    let(:workout) do
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 1.hour.ago
      )
    end
    let(:superset) { supersets(:push_pull) }

    it "returns other sets in the same superset group" do
      set1 =
        WorkoutSet.create!(
          workout: workout,
          exercise: exercises(:bench_press),
          superset: superset,
          superset_group: 1
        )
      set2 =
        WorkoutSet.create!(
          workout: workout,
          exercise: exercises(:pull_up),
          superset: superset,
          superset_group: 1
        )

      expect(set1.superset_sibling_sets).to include(set2)
      expect(set1.superset_sibling_sets).not_to include(set1)
    end

    it "excludes sets from different superset groups" do
      set1 =
        WorkoutSet.create!(
          workout: workout,
          exercise: exercises(:bench_press),
          superset: superset,
          superset_group: 1
        )
      set2 =
        WorkoutSet.create!(
          workout: workout,
          exercise: exercises(:pull_up),
          superset: superset,
          superset_group: 2
        )

      expect(set1.superset_sibling_sets).not_to include(set2)
    end

    it "returns empty when not in a superset" do
      set =
        WorkoutSet.create!(workout: workout, exercise: exercises(:bench_press))
      expect(set.superset_sibling_sets).to be_empty
    end
  end

  describe "#all_superset_sets" do
    let(:user) { users(:john) }
    let(:workout) do
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 1.hour.ago
      )
    end
    let(:superset) { supersets(:push_pull) }

    it "returns all sets in the same superset group including self" do
      set1 =
        WorkoutSet.create!(
          workout: workout,
          exercise: exercises(:bench_press),
          superset: superset,
          superset_group: 1
        )
      set2 =
        WorkoutSet.create!(
          workout: workout,
          exercise: exercises(:pull_up),
          superset: superset,
          superset_group: 1
        )

      expect(set1.all_superset_sets).to include(set1, set2)
    end

    it "returns empty when not in a superset" do
      set =
        WorkoutSet.create!(workout: workout, exercise: exercises(:bench_press))
      expect(set.all_superset_sets).to be_empty
    end
  end
end
