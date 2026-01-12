class AddPauseColumnsToWorkouts < ActiveRecord::Migration[8.0]
  def change
    add_column :workouts, :paused_at, :datetime
    add_column :workouts, :total_paused_seconds, :integer, default: 0
  end
end
