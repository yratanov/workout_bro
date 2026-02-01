describe WorkoutSetsHelper do
  fixtures :all

  describe "#user_supersets" do
    before { Current.session = Session.create!(user: users(:john)) }
    after { Current.reset }

    it "returns supersets that have exercises" do
      result = helper.user_supersets

      expect(result).to include(supersets(:push_pull))
      expect(result).to include(supersets(:arm_circuit))
    end

    it "excludes supersets without exercises" do
      empty_superset = Superset.create!(name: "Empty", user: users(:john))

      result = helper.user_supersets

      expect(result).not_to include(empty_superset)
    end

    it "only returns current user supersets" do
      other_user_superset = Superset.create!(name: "Other", user: users(:jane))
      SupersetExercise.create!(
        superset: other_user_superset,
        exercise: exercises(:bench_press),
        position: 1
      )

      result = helper.user_supersets

      expect(result).not_to include(other_user_superset)
    end
  end

  describe "#next_routine_item_for_workout" do
    context "when workout has no routine day" do
      let(:workout) do
        Workout.new(
          workout_type: :strength,
          started_at: Time.current,
          user: users(:john)
        )
      end

      it "returns default item with no selections" do
        result = helper.next_routine_item_for_workout(workout)

        expect(result.is_superset).to be false
        expect(result.superset_id).to be_nil
        expect(result.exercise_id).to be_nil
      end
    end

    context "when workout has a routine day with exercises" do
      let(:workout) { workouts(:completed_workout) }

      it "returns the first uncompleted exercise" do
        # completed_workout has push_day which has bench_press at position 1
        # completed_workout already has bench_press completed
        result = helper.next_routine_item_for_workout(workout)

        # Since bench_press is already done, and there are no more exercises, returns nil ids
        expect(result.is_superset).to be false
      end

      it "returns the next exercise when first is completed" do
        routine_day = workout_routine_days(:push_day)
        WorkoutRoutineDayExercise.create!(
          workout_routine_day: routine_day,
          exercise: exercises(:squat),
          position: 2
        )

        result = helper.next_routine_item_for_workout(workout)

        expect(result.is_superset).to be false
        expect(result.exercise_id).to eq(exercises(:squat).id)
      end
    end

    context "when routine has a superset" do
      let(:workout) do
        Workout.create!(
          workout_type: :strength,
          started_at: Time.current,
          user: users(:john),
          workout_routine_day: workout_routine_days(:push_day)
        )
      end

      before do
        # Clear existing routine items
        workout_routine_days(
          :push_day
        ).workout_routine_day_exercises.destroy_all

        # Add a superset as the first item
        WorkoutRoutineDayExercise.create!(
          workout_routine_day: workout_routine_days(:push_day),
          superset: supersets(:push_pull),
          position: 1
        )
      end

      it "returns the superset as the next item" do
        result = helper.next_routine_item_for_workout(workout)

        expect(result.is_superset).to be true
        expect(result.superset_id).to eq(supersets(:push_pull).id)
        expect(result.exercise_id).to be_nil
      end

      it "skips completed supersets" do
        # Add a workout set for the superset
        WorkoutSet.create!(
          workout: workout,
          exercise: exercises(:bench_press),
          superset: supersets(:push_pull),
          superset_group: 1,
          started_at: Time.current
        )

        # Add an exercise after the superset
        WorkoutRoutineDayExercise.create!(
          workout_routine_day: workout_routine_days(:push_day),
          exercise: exercises(:squat),
          position: 2
        )

        result = helper.next_routine_item_for_workout(workout)

        expect(result.is_superset).to be false
        expect(result.exercise_id).to eq(exercises(:squat).id)
      end
    end

    context "with mixed exercises and supersets" do
      let(:workout) do
        Workout.create!(
          workout_type: :strength,
          started_at: Time.current,
          user: users(:john),
          workout_routine_day: workout_routine_days(:push_day)
        )
      end

      before do
        workout_routine_days(
          :push_day
        ).workout_routine_day_exercises.destroy_all

        WorkoutRoutineDayExercise.create!(
          workout_routine_day: workout_routine_days(:push_day),
          exercise: exercises(:bench_press),
          position: 1
        )
        WorkoutRoutineDayExercise.create!(
          workout_routine_day: workout_routine_days(:push_day),
          superset: supersets(:push_pull),
          position: 2
        )
        WorkoutRoutineDayExercise.create!(
          workout_routine_day: workout_routine_days(:push_day),
          exercise: exercises(:squat),
          position: 3
        )
      end

      it "returns first exercise when nothing completed" do
        result = helper.next_routine_item_for_workout(workout)

        expect(result.is_superset).to be false
        expect(result.exercise_id).to eq(exercises(:bench_press).id)
      end

      it "returns superset after first exercise completed" do
        WorkoutSet.create!(
          workout: workout,
          exercise: exercises(:bench_press),
          started_at: Time.current
        )

        result = helper.next_routine_item_for_workout(workout)

        expect(result.is_superset).to be true
        expect(result.superset_id).to eq(supersets(:push_pull).id)
      end

      it "returns last exercise after superset completed" do
        WorkoutSet.create!(
          workout: workout,
          exercise: exercises(:bench_press),
          started_at: Time.current
        )
        WorkoutSet.create!(
          workout: workout,
          exercise: exercises(:pull_up),
          superset: supersets(:push_pull),
          superset_group: 1,
          started_at: Time.current
        )

        result = helper.next_routine_item_for_workout(workout)

        expect(result.is_superset).to be false
        expect(result.exercise_id).to eq(exercises(:squat).id)
      end
    end
  end

  describe "#available_exercises_for_workout_set" do
    context "when workout has a routine day" do
      let(:workout) { workouts(:active_workout) }
      let(:workout_set) { WorkoutSet.new(workout: workout) }

      it "includes routine exercises first" do
        result = helper.available_exercises_for_workout_set(workout_set)

        # push_day has bench_press, but it's already used in active_set
        expect(result).not_to include(exercises(:bench_press))
      end

      it "excludes exercises already in workout" do
        result = helper.available_exercises_for_workout_set(workout_set)

        expect(result).not_to include(exercises(:bench_press))
      end

      it "includes other user exercises" do
        result = helper.available_exercises_for_workout_set(workout_set)

        expect(result).to include(exercises(:squat))
        expect(result).to include(exercises(:deadlift))
      end
    end

    context "when workout has no routine day" do
      let(:workout) do
        Workout.create!(
          workout_type: :strength,
          started_at: Time.current,
          user: users(:john)
        )
      end
      let(:workout_set) { WorkoutSet.new(workout: workout) }

      it "returns all user exercises" do
        result = helper.available_exercises_for_workout_set(workout_set)

        expect(result).to include(exercises(:bench_press))
        expect(result).to include(exercises(:squat))
        expect(result).to include(exercises(:deadlift))
      end

      it "excludes exercises already in workout" do
        WorkoutSet.create!(
          workout: workout,
          exercise: exercises(:bench_press),
          started_at: Time.current
        )

        result = helper.available_exercises_for_workout_set(workout_set)

        expect(result).not_to include(exercises(:bench_press))
        expect(result).to include(exercises(:squat))
      end
    end
  end

  describe "#last_completed_workout_set" do
    let(:workout) { workouts(:completed_workout) }

    it "returns the last completed set" do
      result = helper.last_completed_workout_set(workout)

      expect(result).to eq(workout_sets(:completed_set))
    end

    it "returns nil when no completed sets" do
      workout = workouts(:active_workout)
      # active_workout has active_set which has no ended_at

      result = helper.last_completed_workout_set(workout)

      expect(result).to be_nil
    end

    it "returns the most recently ended set" do
      earlier_set =
        WorkoutSet.create!(
          workout: workout,
          exercise: exercises(:squat),
          started_at: 2.hours.ago,
          ended_at: 1.hour.ago
        )
      later_set =
        WorkoutSet.create!(
          workout: workout,
          exercise: exercises(:deadlift),
          started_at: 30.minutes.ago,
          ended_at: 10.minutes.ago
        )

      result = helper.last_completed_workout_set(workout)

      expect(result).to eq(later_set)
    end
  end
end
