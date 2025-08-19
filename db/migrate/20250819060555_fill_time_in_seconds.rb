class FillTimeInSeconds < ActiveRecord::Migration[8.0]
  def change
    Workout.find_each do |workout|
      workout.fill_in_time_in_seconds
      workout.save if workout.changed?
    end
  end
end
