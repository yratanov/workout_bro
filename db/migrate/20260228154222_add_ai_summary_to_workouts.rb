class AddAiSummaryToWorkouts < ActiveRecord::Migration[8.1]
  def change
    add_column :workouts, :ai_summary, :text
  end
end
