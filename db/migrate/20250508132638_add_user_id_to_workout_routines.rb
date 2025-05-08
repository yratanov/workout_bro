class AddUserIdToWorkoutRoutines < ActiveRecord::Migration[8.0]
  def change
    add_reference :workout_routines, :user, foreign_key: true
  end
end
