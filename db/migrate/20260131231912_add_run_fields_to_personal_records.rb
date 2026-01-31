class AddRunFieldsToPersonalRecords < ActiveRecord::Migration[8.1]
  def change
    add_column :personal_records, :distance, :integer
    add_column :personal_records, :pace, :float

    # Make exercise_id and workout_rep_id optional for run PRs
    change_column_null :personal_records, :exercise_id, true
    change_column_null :personal_records, :workout_rep_id, true
    change_column_null :personal_records, :reps, true
  end
end
