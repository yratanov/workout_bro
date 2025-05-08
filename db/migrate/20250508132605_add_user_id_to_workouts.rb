class AddUserIdToWorkouts < ActiveRecord::Migration[8.0]
  def change
    add_reference :workouts, :user, foreign_key: true
  end
end
