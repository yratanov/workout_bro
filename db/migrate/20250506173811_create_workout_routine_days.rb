class CreateWorkoutRoutineDays < ActiveRecord::Migration[8.0]
  def change
    create_table :workout_routine_days do |t|
      t.string :name
      t.references :workout_routine, null: false, foreign_key: true

      t.timestamps
    end
  end
end
