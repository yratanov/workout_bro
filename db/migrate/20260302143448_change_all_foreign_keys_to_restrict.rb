# frozen_string_literal: true

class ChangeAllForeignKeysToRestrict < ActiveRecord::Migration[8.1]
  # Must run outside a transaction so PRAGMA foreign_keys = OFF actually works.
  # Without this, SQLite silently ignores the pragma and CASCADE FKs fire
  # during table rebuilds, deleting child data.
  disable_ddl_transaction!

  FK_CHANGES = [
    { table: :ai_trainer_activities, column: :workout_id, to_table: :workouts },
    {
      table: :ai_trainer_activities,
      column: :ai_trainer_id,
      to_table: :ai_trainers
    },
    {
      table: :workouts,
      column: :workout_import_id,
      to_table: :workout_imports
    },
    {
      table: :workouts,
      column: :workout_routine_day_id,
      to_table: :workout_routine_days
    },
    {
      table: :workout_routine_day_exercises,
      column: :superset_id,
      to_table: :supersets
    },
    { table: :personal_records, column: :exercise_id, to_table: :exercises },
    {
      table: :personal_records,
      column: :workout_rep_id,
      to_table: :workout_reps
    },
    { table: :personal_records, column: :workout_id, to_table: :workouts },
    { table: :workout_sets, column: :superset_id, to_table: :supersets },
    { table: :exercises, column: :muscle_id, to_table: :muscles },
    { table: :ai_trainers, column: :user_id, to_table: :users },
    { table: :invites, column: :used_by_user_id, to_table: :users },
    { table: :superset_exercises, column: :superset_id, to_table: :supersets }
  ].freeze

  def up
    FK_CHANGES.each do |fk|
      remove_foreign_key fk[:table], fk[:to_table], column: fk[:column]
      add_foreign_key fk[:table], fk[:to_table], column: fk[:column]
    end
  end

  def down
    # No-op: we don't want to restore cascade/nullify behavior
  end
end
