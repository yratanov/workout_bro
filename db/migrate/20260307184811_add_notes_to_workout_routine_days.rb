class AddNotesToWorkoutRoutineDays < ActiveRecord::Migration[8.1]
  def change
    add_column :workout_routine_days, :notes, :text
  end
end
