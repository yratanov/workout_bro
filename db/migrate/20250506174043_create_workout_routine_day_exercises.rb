class CreateWorkoutRoutineDayExercises < ActiveRecord::Migration[8.0]
  def change
    create_table :workout_routine_day_exercises do |t|
      t.references :workout_routine_day, null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: true

      t.timestamps
    end
  end
end
