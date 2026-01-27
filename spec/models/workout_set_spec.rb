# == Schema Information
#
# Table name: workout_sets
# Database name: primary
#
#  id                   :integer          not null, primary key
#  ended_at             :datetime
#  paused_at            :datetime
#  started_at           :datetime
#  total_paused_seconds :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  exercise_id          :integer          not null
#  workout_id           :integer          not null
#
# Indexes
#
#  index_workout_sets_on_exercise_id  (exercise_id)
#  index_workout_sets_on_workout_id   (workout_id)
#
# Foreign Keys
#
#  exercise_id  (exercise_id => exercises.id)
#  workout_id   (workout_id => workouts.id)
#
require 'rails_helper'

describe WorkoutSet do
  fixtures :users, :workouts, :exercises, :workout_sets, :workout_reps

  describe '#default_rep_values' do
    let(:user) { users(:john) }
    let(:exercise) { exercises(:bench_press) }

    context 'when previous workout has a rep at the same index' do
      it 'returns values from the previous workout rep at the same index' do
        # Create a completed workout with reps
        old_workout = Workout.create!(user: user, workout_type: 'strength', started_at: 2.days.ago, ended_at: 2.days.ago + 1.hour)
        old_set = WorkoutSet.create!(workout: old_workout, exercise: exercise, started_at: 2.days.ago, ended_at: 2.days.ago + 10.minutes)
        old_set.workout_reps.create!(reps: 12, weight: 80, band: 'heavy')
        old_set.workout_reps.create!(reps: 10, weight: 85, band: 'medium')

        # Create current workout set with one rep already
        current_workout = Workout.create!(user: user, workout_type: 'strength', started_at: 1.hour.ago)
        current_set = WorkoutSet.create!(workout: current_workout, exercise: exercise, started_at: 1.hour.ago)
        current_set.workout_reps.create!(reps: 15, weight: 70, band: nil)

        # Should get values from old_set's second rep (index 1)
        defaults = current_set.default_rep_values
        expect(defaults[:reps]).to eq(10)
        expect(defaults[:weight]).to eq(85)
        expect(defaults[:band]).to eq('medium')
      end
    end

    context 'when previous workout has no rep at the same index but current set has reps' do
      it 'returns values from the last rep in current set' do
        # Create a completed workout with only one rep
        old_workout = Workout.create!(user: user, workout_type: 'strength', started_at: 2.days.ago, ended_at: 2.days.ago + 1.hour)
        old_set = WorkoutSet.create!(workout: old_workout, exercise: exercise, started_at: 2.days.ago, ended_at: 2.days.ago + 10.minutes)
        old_set.workout_reps.create!(reps: 12, weight: 80, band: nil)

        # Create current workout set with two reps already (so index 2 won't exist in old_set)
        current_workout = Workout.create!(user: user, workout_type: 'strength', started_at: 1.hour.ago)
        current_set = WorkoutSet.create!(workout: current_workout, exercise: exercise, started_at: 1.hour.ago)
        current_set.workout_reps.create!(reps: 15, weight: 70, band: nil)
        current_set.workout_reps.create!(reps: 14, weight: 75, band: 'light')

        # Should get values from current_set's last rep
        defaults = current_set.default_rep_values
        expect(defaults[:reps]).to eq(14)
        expect(defaults[:weight]).to eq(75)
        expect(defaults[:band]).to eq('light')
      end
    end

    context 'when there are no previous reps anywhere' do
      it 'returns default values' do
        # Create a new exercise with no history
        new_exercise = Exercise.create!(name: 'New Exercise', user: user)

        current_workout = Workout.create!(user: user, workout_type: 'strength', started_at: 1.hour.ago)
        current_set = WorkoutSet.create!(workout: current_workout, exercise: new_exercise, started_at: 1.hour.ago)

        defaults = current_set.default_rep_values
        expect(defaults[:reps]).to eq(10)
        expect(defaults[:weight]).to eq(10)
        expect(defaults[:band]).to be_nil
      end
    end
  end
end
