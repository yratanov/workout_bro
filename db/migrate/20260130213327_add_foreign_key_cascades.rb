class AddForeignKeyCascades < ActiveRecord::Migration[8.1]
  def change
    # Muscle → exercises: nullify when muscle is deleted
    remove_foreign_key :exercises, :muscles
    add_foreign_key :exercises, :muscles, on_delete: :nullify

    # User (used_by_user_id) → invites: nullify when user is deleted
    remove_foreign_key :invites, :users, column: :used_by_user_id
    add_foreign_key :invites, :users, column: :used_by_user_id, on_delete: :nullify

    # WorkoutImport → workouts: nullify when import is deleted
    remove_foreign_key :workouts, :workout_imports
    add_foreign_key :workouts, :workout_imports, on_delete: :nullify

    # WorkoutRoutineDay → workouts: nullify when routine day is deleted
    remove_foreign_key :workouts, :workout_routine_days
    add_foreign_key :workouts, :workout_routine_days, on_delete: :nullify

    # Exercise → workout_sets: restrict deletion of exercise with workout sets
    remove_foreign_key :workout_sets, :exercises
    add_foreign_key :workout_sets, :exercises, on_delete: :restrict
  end
end
