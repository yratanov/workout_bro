class AddGarminMetricsToWorkouts < ActiveRecord::Migration[8.1]
  def change
    add_column :workouts, :avg_heart_rate, :integer
    add_column :workouts, :max_heart_rate, :integer
    add_column :workouts, :avg_cadence, :integer
    add_column :workouts, :elevation_gain, :float
    add_column :workouts, :vo2max, :float
  end
end
