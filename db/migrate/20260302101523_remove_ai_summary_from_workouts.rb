class RemoveAiSummaryFromWorkouts < ActiveRecord::Migration[8.1]
  def change
    remove_column :workouts, :ai_summary, :text
  end
end
