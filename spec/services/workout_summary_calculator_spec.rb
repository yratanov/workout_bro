describe WorkoutSummaryCalculator do
  fixtures :users,
           :exercises,
           :muscles,
           :workout_routines,
           :workout_routine_days

  let(:user) { users(:john) }
  let(:bench_press) { exercises(:bench_press) }
  let(:squat) { exercises(:squat) }
  let(:pull_up) { exercises(:pull_up) }
  let(:push_day) { workout_routine_days(:push_day) }

  # Clean up fixture workouts to avoid interference
  before { user.workouts.destroy_all }

  describe "#call" do
    context "with strength workout" do
      let(:workout) do
        Workout.create!(
          user: user,
          workout_type: :strength,
          started_at: 1.hour.ago,
          ended_at: Time.current,
          workout_routine_day: push_day
        )
      end

      it "calculates total volume correctly" do
        workout_set =
          workout.workout_sets.create!(
            exercise: bench_press,
            started_at: 30.minutes.ago,
            ended_at: 20.minutes.ago
          )
        workout_set.workout_reps.create!(weight: 100, reps: 10) # 1000
        workout_set.workout_reps.create!(weight: 90, reps: 8) # 720
        workout_set.workout_reps.create!(weight: 80, reps: 6) # 480

        result = described_class.new(workout: workout).call

        expect(result.total_volume).to eq(2200)
      end

      it "counts total sets" do
        workout.workout_sets.create!(
          exercise: bench_press,
          started_at: 30.minutes.ago,
          ended_at: 20.minutes.ago
        )
        workout.workout_sets.create!(
          exercise: squat,
          started_at: 15.minutes.ago,
          ended_at: 5.minutes.ago
        )

        result = described_class.new(workout: workout).call

        expect(result.total_sets).to eq(2)
      end

      it "counts total reps" do
        workout_set =
          workout.workout_sets.create!(
            exercise: bench_press,
            started_at: 30.minutes.ago,
            ended_at: 20.minutes.ago
          )
        workout_set.workout_reps.create!(weight: 100, reps: 10)
        workout_set.workout_reps.create!(weight: 90, reps: 8)

        result = described_class.new(workout: workout).call

        expect(result.total_reps).to eq(18)
      end

      it "returns unique muscles worked" do
        workout.workout_sets.create!(
          exercise: bench_press,
          started_at: 30.minutes.ago,
          ended_at: 20.minutes.ago
        )
        workout.workout_sets.create!(
          exercise: squat,
          started_at: 15.minutes.ago,
          ended_at: 5.minutes.ago
        )

        result = described_class.new(workout: workout).call

        muscle_names = result.muscles_worked.map(&:name)
        expect(muscle_names).to contain_exactly("chest", "legs")
      end

      it "returns workout duration" do
        result = described_class.new(workout: workout).call

        expect(result.duration).to eq(workout.time_in_seconds)
      end

      it "finds previous workout by workout_routine_day_id" do
        previous_workout =
          Workout.create!(
            user: user,
            workout_type: :strength,
            started_at: 1.week.ago,
            ended_at: 1.week.ago + 1.hour,
            workout_routine_day: push_day
          )

        result = described_class.new(workout: workout).call

        expect(result.previous_workout).to eq(previous_workout)
      end

      it "finds previous workout by exercise overlap for custom workouts" do
        custom_workout =
          Workout.create!(
            user: user,
            workout_type: :strength,
            started_at: 1.hour.ago,
            ended_at: Time.current,
            workout_routine_day: nil
          )
        custom_workout.workout_sets.create!(
          exercise: bench_press,
          started_at: 30.minutes.ago
        )
        custom_workout.workout_sets.create!(
          exercise: squat,
          started_at: 20.minutes.ago
        )

        previous_custom =
          Workout.create!(
            user: user,
            workout_type: :strength,
            started_at: 1.week.ago,
            ended_at: 1.week.ago + 1.hour,
            workout_routine_day: nil
          )
        previous_custom.workout_sets.create!(
          exercise: bench_press,
          started_at: 1.week.ago + 10.minutes
        )
        previous_custom.workout_sets.create!(
          exercise: squat,
          started_at: 1.week.ago + 20.minutes
        )

        result = described_class.new(workout: custom_workout).call

        expect(result.previous_workout).to eq(previous_custom)
      end

      it "does not match previous workout with insufficient overlap" do
        custom_workout =
          Workout.create!(
            user: user,
            workout_type: :strength,
            started_at: 1.hour.ago,
            ended_at: Time.current,
            workout_routine_day: nil
          )
        custom_workout.workout_sets.create!(
          exercise: bench_press,
          started_at: 30.minutes.ago
        )
        custom_workout.workout_sets.create!(
          exercise: squat,
          started_at: 25.minutes.ago
        )
        custom_workout.workout_sets.create!(
          exercise: pull_up,
          started_at: 20.minutes.ago
        )

        # Previous workout with only 1 out of 3 exercises (33% overlap)
        previous_custom =
          Workout.create!(
            user: user,
            workout_type: :strength,
            started_at: 1.week.ago,
            ended_at: 1.week.ago + 1.hour,
            workout_routine_day: nil
          )
        previous_custom.workout_sets.create!(
          exercise: bench_press,
          started_at: 1.week.ago + 10.minutes
        )

        result = described_class.new(workout: custom_workout).call

        expect(result.previous_workout).to be_nil
      end

      it "calculates volume comparison as percentage" do
        previous_workout =
          Workout.create!(
            user: user,
            workout_type: :strength,
            started_at: 1.week.ago,
            ended_at: 1.week.ago + 1.hour,
            workout_routine_day: push_day
          )
        prev_set =
          previous_workout.workout_sets.create!(
            exercise: bench_press,
            started_at: 1.week.ago + 10.minutes
          )
        prev_set.workout_reps.create!(weight: 100, reps: 10) # 1000

        current_set =
          workout.workout_sets.create!(
            exercise: bench_press,
            started_at: 30.minutes.ago
          )
        current_set.workout_reps.create!(weight: 100, reps: 12) # 1200

        result = described_class.new(workout: workout).call

        expect(result.comparison.volume_diff).to eq(200)
        expect(result.comparison.volume_diff_percent).to eq(20.0)
      end

      it "includes passed PRs in summary" do
        pr =
          user.personal_records.create!(
            exercise: bench_press,
            workout: workout,
            workout_rep:
              workout
                .workout_sets
                .create!(exercise: bench_press, started_at: 30.minutes.ago)
                .workout_reps
                .create!(weight: 100, reps: 10),
            pr_type: :max_weight,
            weight: 100,
            reps: 10,
            achieved_on: Date.current
          )

        result = described_class.new(workout: workout, new_prs: [pr]).call

        expect(result.new_prs).to eq([pr])
      end
    end

    context "with run workout" do
      let(:run_workout) do
        Workout.create!(
          user: user,
          workout_type: :run,
          started_at: 30.minutes.ago,
          ended_at: Time.current,
          distance: 5000,
          time_in_seconds: 1800
        )
      end

      it "returns run-specific stats" do
        result = described_class.new(workout: run_workout).call

        expect(result.distance).to eq(5000)
        expect(result.duration).to eq(1800)
        expect(result.pace).to eq(360.0) # 6 min/km in seconds
      end

      it "finds previous run for comparison" do
        previous_run =
          Workout.create!(
            user: user,
            workout_type: :run,
            started_at: 1.week.ago,
            ended_at: 1.week.ago + 30.minutes,
            distance: 5000,
            time_in_seconds: 1800
          )

        result = described_class.new(workout: run_workout).call

        expect(result.previous_workout).to eq(previous_run)
      end

      it "calculates pace difference in seconds" do
        # 6:00/km pace (1800s for 5km)
        prev_start = 1.week.ago
        Workout.create!(
          user: user,
          workout_type: :run,
          started_at: prev_start,
          ended_at: prev_start + 1800.seconds,
          distance: 5000,
          time_in_seconds: 1800
        )

        # 5:45/km pace (1725s for 5km)
        current_start = 1.hour.ago
        faster_run =
          Workout.create!(
            user: user,
            workout_type: :run,
            started_at: current_start,
            ended_at: current_start + 1725.seconds,
            distance: 5000,
            time_in_seconds: 1725
          )

        result = described_class.new(workout: faster_run).call

        expect(result.comparison.pace_diff).to eq(15.0) # 15 seconds faster per km
      end
    end

    context "edge cases" do
      it "handles workout with no sets" do
        workout =
          Workout.create!(
            user: user,
            workout_type: :strength,
            started_at: 1.hour.ago,
            ended_at: Time.current,
            workout_routine_day: push_day
          )

        result = described_class.new(workout: workout).call

        expect(result.total_volume).to eq(0)
        expect(result.total_sets).to eq(0)
        expect(result.total_reps).to eq(0)
        expect(result.muscles_worked).to be_empty
      end

      it "handles exercises without muscle association" do
        exercise_without_muscle =
          Exercise.create!(
            name: "Mystery Exercise",
            user: user,
            with_weights: true,
            muscle: nil
          )

        workout =
          Workout.create!(
            user: user,
            workout_type: :strength,
            started_at: 1.hour.ago,
            ended_at: Time.current
          )
        workout.workout_sets.create!(
          exercise: exercise_without_muscle,
          started_at: 30.minutes.ago
        )

        result = described_class.new(workout: workout).call

        expect(result.muscles_worked).to be_empty
      end

      it "returns nil comparison when no previous workout" do
        workout =
          Workout.create!(
            user: user,
            workout_type: :strength,
            started_at: 1.hour.ago,
            ended_at: Time.current,
            workout_routine_day: nil
          )

        result = described_class.new(workout: workout).call

        expect(result.previous_workout).to be_nil
        expect(result.comparison).to be_nil
      end

      it "handles reps with nil weight (bodyweight exercises)" do
        workout =
          Workout.create!(
            user: user,
            workout_type: :strength,
            started_at: 1.hour.ago,
            ended_at: Time.current
          )
        workout_set =
          workout.workout_sets.create!(
            exercise: pull_up,
            started_at: 30.minutes.ago
          )
        workout_set.workout_reps.create!(weight: nil, reps: 10)

        result = described_class.new(workout: workout).call

        expect(result.total_volume).to eq(0)
        expect(result.total_reps).to eq(10)
      end
    end
  end
end
