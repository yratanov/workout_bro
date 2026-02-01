# == Schema Information
#
# Table name: workout_routine_day_exercises
# Database name: primary
#
#  id                     :integer          not null, primary key
#  position               :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  exercise_id            :integer
#  superset_id            :integer
#  workout_routine_day_id :integer          not null
#
# Indexes
#
#  index_workout_routine_day_exercises_on_exercise_id             (exercise_id)
#  index_workout_routine_day_exercises_on_superset_id             (superset_id)
#  index_workout_routine_day_exercises_on_workout_routine_day_id  (workout_routine_day_id)
#
# Foreign Keys
#
#  exercise_id             (exercise_id => exercises.id)
#  superset_id             (superset_id => supersets.id) ON DELETE => cascade
#  workout_routine_day_id  (workout_routine_day_id => workout_routine_days.id)
#
describe WorkoutRoutineDayExercise do
  fixtures :users,
           :exercises,
           :supersets,
           :superset_exercises,
           :workout_routines,
           :workout_routine_days

  let(:routine_day) { workout_routine_days(:push_day) }

  describe "validations" do
    it "is valid with only exercise" do
      wrde =
        WorkoutRoutineDayExercise.new(
          workout_routine_day: routine_day,
          exercise: exercises(:squat)
        )
      expect(wrde).to be_valid
    end

    it "is valid with only superset" do
      wrde =
        WorkoutRoutineDayExercise.new(
          workout_routine_day: routine_day,
          superset: supersets(:push_pull)
        )
      expect(wrde).to be_valid
    end

    it "is invalid without exercise or superset" do
      wrde = WorkoutRoutineDayExercise.new(workout_routine_day: routine_day)
      expect(wrde).not_to be_valid
      expect(wrde.errors[:base]).to include(
        I18n.t("errors.messages.exercise_or_superset_required")
      )
    end

    it "is invalid with both exercise and superset" do
      wrde =
        WorkoutRoutineDayExercise.new(
          workout_routine_day: routine_day,
          exercise: exercises(:squat),
          superset: supersets(:push_pull)
        )
      expect(wrde).not_to be_valid
      expect(wrde.errors[:base]).to include(
        I18n.t("errors.messages.exercise_xor_superset")
      )
    end
  end

  describe "#superset?" do
    it "returns true when superset_id is present" do
      wrde =
        WorkoutRoutineDayExercise.new(
          workout_routine_day: routine_day,
          superset: supersets(:push_pull)
        )
      expect(wrde.superset?).to be true
    end

    it "returns false when superset_id is blank" do
      wrde =
        WorkoutRoutineDayExercise.new(
          workout_routine_day: routine_day,
          exercise: exercises(:squat)
        )
      expect(wrde.superset?).to be false
    end
  end

  describe "#display_name" do
    it "returns exercise name when has exercise" do
      wrde =
        WorkoutRoutineDayExercise.new(
          workout_routine_day: routine_day,
          exercise: exercises(:squat)
        )
      expect(wrde.display_name).to eq("Squat")
    end

    it "returns superset display_name when has superset" do
      wrde =
        WorkoutRoutineDayExercise.new(
          workout_routine_day: routine_day,
          superset: supersets(:push_pull)
        )
      expect(wrde.display_name).to eq("Push Pull")
    end
  end
end
