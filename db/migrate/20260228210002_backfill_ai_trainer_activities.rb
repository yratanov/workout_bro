class BackfillAiTrainerActivities < ActiveRecord::Migration[8.1]
  def up
    # Copy ai_trainer.summary → ai_trainer.trainer_profile for completed trainers
    execute <<~SQL
      UPDATE ai_trainers
      SET trainer_profile = summary
      WHERE status = 2 AND summary IS NOT NULL
    SQL

    # Convert weekly_reports → ai_trainer_activities (type: weekly_report = 2)
    execute <<~SQL
      INSERT INTO ai_trainer_activities (user_id, ai_trainer_id, activity_type, content, status, week_start, viewed_at, created_at, updated_at)
      SELECT wr.user_id, at2.id, 2, wr.ai_summary,
             CASE wr.status WHEN 0 THEN 0 WHEN 1 THEN 1 WHEN 2 THEN 2 ELSE 0 END,
             wr.week_start, wr.viewed_at, wr.created_at, wr.updated_at
      FROM weekly_reports wr
      INNER JOIN ai_trainers at2 ON at2.user_id = wr.user_id
    SQL

    # Convert workout.ai_summary → ai_trainer_activities (type: workout_review = 1)
    execute <<~SQL
      INSERT INTO ai_trainer_activities (user_id, ai_trainer_id, workout_id, activity_type, content, status, created_at, updated_at)
      SELECT w.user_id, at2.id, w.id, 1, w.ai_summary, 1, w.updated_at, w.updated_at
      FROM workouts w
      INNER JOIN ai_trainers at2 ON at2.user_id = w.user_id
      WHERE w.ai_summary IS NOT NULL
    SQL
  end

  def down
    execute "DELETE FROM ai_trainer_activities"
    execute "UPDATE ai_trainers SET trainer_profile = NULL"
  end
end
