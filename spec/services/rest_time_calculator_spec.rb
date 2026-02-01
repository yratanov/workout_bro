describe RestTimeCalculator do
  fixtures :users, :exercises, :muscles

  let(:user) { users(:john) }
  let(:bench_press) { exercises(:bench_press) }
  let(:squat) { exercises(:squat) }
  let(:bicep_curl) { exercises(:bicep_curl) }

  let(:workout) do
    Workout.create!(user: user, workout_type: :strength, started_at: 1.hour.ago)
  end

  describe "#recommended_seconds" do
    context "with small muscle group and light weight" do
      let(:workout_set) do
        workout.workout_sets.create!(
          exercise: bicep_curl,
          started_at: 30.minutes.ago
        )
      end

      it "returns base rest time of 60 seconds" do
        workout_set.workout_reps.create!(weight: 10, reps: 10)

        result =
          described_class.new(
            workout_set: workout_set,
            user: user
          ).recommended_seconds

        expect(result).to eq(60)
      end
    end

    context "with large muscle group" do
      let(:legs_muscle) { muscles(:legs) }
      let(:leg_exercise) { squat }

      let(:workout_set) do
        workout.workout_sets.create!(
          exercise: leg_exercise,
          started_at: 30.minutes.ago
        )
      end

      it "adds 30 seconds for large muscle groups" do
        workout_set.workout_reps.create!(weight: 50, reps: 10)

        result =
          described_class.new(
            workout_set: workout_set,
            user: user
          ).recommended_seconds

        expect(result).to eq(90)
      end
    end

    context "with heavy lift near PR" do
      let(:workout_set) do
        workout.workout_sets.create!(
          exercise: bicep_curl,
          started_at: 30.minutes.ago
        )
      end

      before do
        pr_workout =
          Workout.create!(
            user: user,
            workout_type: :strength,
            started_at: 2.weeks.ago,
            ended_at: 2.weeks.ago + 1.hour
          )
        pr_set =
          pr_workout.workout_sets.create!(
            exercise: bicep_curl,
            started_at: 2.weeks.ago + 10.minutes,
            ended_at: 2.weeks.ago + 20.minutes
          )
        pr_rep = pr_set.workout_reps.create!(weight: 20, reps: 10)

        user.personal_records.create!(
          exercise: bicep_curl,
          workout: pr_workout,
          workout_rep: pr_rep,
          pr_type: :max_weight,
          weight: 20,
          reps: 10,
          achieved_on: 2.weeks.ago.to_date
        )
      end

      it "adds 30 seconds for heavy lifts (>= 85% of PR)" do
        workout_set.workout_reps.create!(weight: 17, reps: 10) # 85% of 20

        result =
          described_class.new(
            workout_set: workout_set,
            user: user
          ).recommended_seconds

        expect(result).to eq(90)
      end

      it "does not add extra time for lighter lifts (< 85% of PR)" do
        workout_set.workout_reps.create!(weight: 16, reps: 10) # 80% of 20

        result =
          described_class.new(
            workout_set: workout_set,
            user: user
          ).recommended_seconds

        expect(result).to eq(60)
      end
    end

    context "with both large muscle group and heavy lift" do
      let(:workout_set) do
        workout.workout_sets.create!(
          exercise: squat,
          started_at: 30.minutes.ago
        )
      end

      before do
        pr_workout =
          Workout.create!(
            user: user,
            workout_type: :strength,
            started_at: 2.weeks.ago,
            ended_at: 2.weeks.ago + 1.hour
          )
        pr_set =
          pr_workout.workout_sets.create!(
            exercise: squat,
            started_at: 2.weeks.ago + 10.minutes,
            ended_at: 2.weeks.ago + 20.minutes
          )
        pr_rep = pr_set.workout_reps.create!(weight: 150, reps: 5)

        user.personal_records.create!(
          exercise: squat,
          workout: pr_workout,
          workout_rep: pr_rep,
          pr_type: :max_weight,
          weight: 150,
          reps: 5,
          achieved_on: 2.weeks.ago.to_date
        )
      end

      it "adds 60 seconds total (30 for large muscle + 30 for heavy lift)" do
        workout_set.workout_reps.create!(weight: 140, reps: 5)

        result =
          described_class.new(
            workout_set: workout_set,
            user: user
          ).recommended_seconds

        expect(result).to eq(120)
      end
    end

    context "with no reps yet" do
      let(:workout_set) do
        workout.workout_sets.create!(
          exercise: bicep_curl,
          started_at: 30.minutes.ago
        )
      end

      it "returns base rest time for small muscle" do
        result =
          described_class.new(
            workout_set: workout_set,
            user: user
          ).recommended_seconds

        expect(result).to eq(60)
      end
    end

    context "with exercise without muscle" do
      let(:exercise_without_muscle) do
        Exercise.create!(
          name: "Mystery Exercise",
          user: user,
          with_weights: true,
          muscle: nil
        )
      end

      let(:workout_set) do
        workout.workout_sets.create!(
          exercise: exercise_without_muscle,
          started_at: 30.minutes.ago
        )
      end

      it "returns base rest time" do
        workout_set.workout_reps.create!(weight: 50, reps: 10)

        result =
          described_class.new(
            workout_set: workout_set,
            user: user
          ).recommended_seconds

        expect(result).to eq(60)
      end
    end
  end
end
