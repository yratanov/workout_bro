class AddPauseColumnsToWorkoutSets < ActiveRecord::Migration[8.0]
  def change
    add_column :workout_sets, :paused_at, :datetime
    add_column :workout_sets, :total_paused_seconds, :integer, default: 0
  end
end
