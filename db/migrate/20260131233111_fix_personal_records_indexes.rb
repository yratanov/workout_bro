class FixPersonalRecordsIndexes < ActiveRecord::Migration[8.0]
  def change
    # Remove redundant index (user_id is already covered by composite index)
    remove_index :personal_records, :user_id

    # Make workout_rep_id index unique (one PR per workout_rep)
    # Only applies when workout_rep_id is not null (run PRs don't have workout_rep)
    remove_index :personal_records, :workout_rep_id
    add_index :personal_records,
              :workout_rep_id,
              unique: true,
              where: "workout_rep_id IS NOT NULL"
  end
end
