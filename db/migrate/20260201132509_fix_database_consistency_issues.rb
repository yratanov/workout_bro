class FixDatabaseConsistencyIssues < ActiveRecord::Migration[8.0]
  def change
    # Remove redundant indexes (covered by composite indexes)
    remove_index :workout_sets, :workout_id
    remove_index :superset_exercises, :superset_id

    # Add unique index for superset_exercise validation
    add_index :superset_exercises, [:superset_id, :exercise_id], unique: true

    # Fix foreign key cascade on workout_sets.superset_id
    remove_foreign_key :workout_sets, :supersets
    add_foreign_key :workout_sets, :supersets, on_delete: :nullify
  end
end
