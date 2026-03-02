class FixDatabaseConsistencyIssuesV2 < ActiveRecord::Migration[8.1]
  def change
    # Remove redundant indexes (covered by composite indexes)
    remove_index :weekly_reports, :user_id
    remove_index :ai_trainer_activities, :ai_trainer_id
    remove_index :ai_trainer_activities, :user_id

    # Make workout_id unique for has_one association
    remove_index :ai_trainer_activities, :workout_id
    add_index :ai_trainer_activities, :workout_id, unique: true
  end
end
