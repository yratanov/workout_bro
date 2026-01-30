class AddNotNullConstraints < ActiveRecord::Migration[8.1]
  def change
    change_column_null :workout_routine_days, :name, false
    change_column_null :workout_routines, :user_id, false
    change_column_null :workout_reps, :reps, false
    change_column_null :workouts, :user_id, false
    change_column_null :workouts, :started_at, false
    change_column_default :users, :setup_completed, from: nil, to: false
    change_column_null :users, :setup_completed, false, false
  end
end
