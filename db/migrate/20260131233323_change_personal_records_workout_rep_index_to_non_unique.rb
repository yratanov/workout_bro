class ChangePersonalRecordsWorkoutRepIndexToNonUnique < ActiveRecord::Migration[8.0]
  def change
    # A workout_rep can have multiple PRs (e.g., max_weight and max_volume)
    remove_index :personal_records, :workout_rep_id
    add_index :personal_records, :workout_rep_id
  end
end
