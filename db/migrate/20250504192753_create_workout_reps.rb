class CreateWorkoutReps < ActiveRecord::Migration[8.0]
  def change
    create_table :workout_reps do |t|
      t.float :weight
      t.integer :reps
      t.references :workout_set, null: false, foreign_key: true

      t.timestamps
    end
  end
end
