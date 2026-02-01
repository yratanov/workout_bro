# == Schema Information
#
# Table name: superset_exercises
# Database name: primary
#
#  id          :integer          not null, primary key
#  position    :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  exercise_id :integer          not null
#  superset_id :integer          not null
#
# Indexes
#
#  index_superset_exercises_on_exercise_id                  (exercise_id)
#  index_superset_exercises_on_superset_id_and_exercise_id  (superset_id,exercise_id) UNIQUE
#  index_superset_exercises_on_superset_id_and_position     (superset_id,position)
#
# Foreign Keys
#
#  exercise_id  (exercise_id => exercises.id)
#  superset_id  (superset_id => supersets.id) ON DELETE => cascade
#
describe SupersetExercise do
  fixtures :users, :exercises, :supersets, :superset_exercises

  describe "validations" do
    it "requires a position" do
      se =
        SupersetExercise.new(
          superset: supersets(:push_pull),
          exercise: exercises(:squat)
        )
      expect(se).not_to be_valid
      expect(se.errors[:position]).to include("can't be blank")
    end

    it "requires position to be greater than 0" do
      se =
        SupersetExercise.new(
          superset: supersets(:push_pull),
          exercise: exercises(:squat),
          position: 0
        )
      expect(se).not_to be_valid
      expect(se.errors[:position]).to include("must be greater than 0")
    end

    it "does not allow duplicate exercise in same superset" do
      se =
        SupersetExercise.new(
          superset: supersets(:push_pull),
          exercise: exercises(:bench_press),
          position: 3
        )
      expect(se).not_to be_valid
      expect(se.errors[:exercise_id]).to include("has already been taken")
    end

    it "allows same exercise in different supersets" do
      se =
        SupersetExercise.new(
          superset: supersets(:arm_circuit),
          exercise: exercises(:bench_press),
          position: 3
        )
      expect(se).to be_valid
    end

    it "is valid with all required attributes" do
      se =
        SupersetExercise.new(
          superset: supersets(:push_pull),
          exercise: exercises(:squat),
          position: 3
        )
      expect(se).to be_valid
    end
  end

  describe "associations" do
    let(:superset_exercise) { superset_exercises(:push_pull_bench) }

    it "belongs to a superset" do
      expect(superset_exercise.superset).to eq(supersets(:push_pull))
    end

    it "belongs to an exercise" do
      expect(superset_exercise.exercise).to eq(exercises(:bench_press))
    end
  end
end
