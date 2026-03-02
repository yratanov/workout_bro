class AddAiStatusToWorkoutRoutines < ActiveRecord::Migration[8.1]
  def change
    add_column :workout_routines, :ai_status, :integer
    add_column :workout_routines, :ai_generation_error, :string
  end
end
