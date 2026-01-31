class FixPersonalRecordsIndexes < ActiveRecord::Migration[8.0]
  def change
    # Remove redundant index (user_id is already covered by composite index)
    remove_index :personal_records, :user_id
    # Note: workout_rep_id index is left as-is (non-unique) because
    # a workout_rep can have multiple PRs (e.g., max_weight and max_volume)
  end
end
