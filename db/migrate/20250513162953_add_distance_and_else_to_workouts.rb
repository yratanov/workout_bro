class AddDistanceAndElseToWorkouts < ActiveRecord::Migration[8.0]
  def change
    add_column :workouts, :distance, :integer
    add_column :workouts, :time_in_seconds, :integer
  end
end
