class BackfillRunPersonalRecords < ActiveRecord::Migration[8.0]
  def up
    User.find_each do |user|
      backfill_run_prs_for_user(user)
    end
  end

  def down
    PersonalRecord.where(pr_type: [:longest_distance, :fastest_pace]).delete_all
  end

  private

  def backfill_run_prs_for_user(user)
    runs =
      user
        .workouts
        .where(workout_type: :run)
        .where.not(ended_at: nil)
        .where("distance > 0")
        .order(:started_at)

    best_distance = 0
    best_pace = Float::INFINITY

    runs.find_each do |run|
      # Check for longest distance PR
      if run.distance > best_distance
        best_distance = run.distance
        create_pr(user, run, :longest_distance, distance: run.distance)
      end

      # Check for fastest pace PR
      pace = run.pace
      next unless pace && pace < best_pace

      best_pace = pace
      create_pr(user, run, :fastest_pace, distance: run.distance, pace: pace)
    end
  end

  def create_pr(user, workout, pr_type, attrs = {})
    PersonalRecord.create!(
      user: user,
      workout: workout,
      pr_type: pr_type,
      achieved_on: workout.started_at.to_date,
      **attrs
    )
  end
end
