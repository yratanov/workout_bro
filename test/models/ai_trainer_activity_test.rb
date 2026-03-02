require "test_helper"

# == Schema Information
#
# Table name: ai_trainer_activities
# Database name: primary
#
#  id            :integer          not null, primary key
#  activity_type :integer          not null
#  content       :text
#  error_message :text
#  status        :integer          default("pending"), not null
#  viewed_at     :datetime
#  week_start    :date
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  ai_trainer_id :integer
#  user_id       :integer          not null
#  workout_id    :integer
#
# Indexes
#
#  idx_activities_trainer_type_created                       (ai_trainer_id,activity_type,created_at)
#  index_ai_trainer_activities_on_user_id_and_activity_type  (user_id,activity_type)
#  index_ai_trainer_activities_on_user_id_and_created_at     (user_id,created_at)
#  index_ai_trainer_activities_on_workout_id                 (workout_id) UNIQUE
#
# Foreign Keys
#
#  ai_trainer_id  (ai_trainer_id => ai_trainers.id)
#  user_id        (user_id => users.id)
#  workout_id     (workout_id => workouts.id)
#

class AiTrainerActivityTest < ActiveSupport::TestCase
  test "defines activity_type enum" do
    assert_equal(
      { "full_review" => 0, "workout_review" => 1, "weekly_report" => 2 },
      AiTrainerActivity.activity_types
    )
  end

  test "defines status enum" do
    assert_equal(
      { "pending" => 0, "completed" => 1, "failed" => 2 },
      AiTrainerActivity.statuses
    )
  end

  test "belongs to user" do
    activity = ai_trainer_activities(:johns_workout_review)
    assert_equal users(:john), activity.user
  end

  test "belongs to ai_trainer" do
    activity = ai_trainer_activities(:johns_workout_review)
    assert_equal ai_trainers(:johns_trainer), activity.ai_trainer
  end

  test "optionally belongs to workout" do
    activity = ai_trainer_activities(:johns_workout_review)
    assert_equal workouts(:completed_workout), activity.workout

    report = ai_trainer_activities(:johns_weekly_report)
    assert_nil report.workout
  end

  test "recent scope orders by created_at desc" do
    activities = AiTrainerActivity.recent
    assert activities.first.created_at >= activities.last.created_at
  end

  test "unviewed returns completed activities without viewed_at" do
    unviewed = users(:john).ai_trainer_activities.unviewed
    assert_includes unviewed, ai_trainer_activities(:johns_workout_review)
    assert_includes unviewed, ai_trainer_activities(:johns_unviewed_report)
    assert_not_includes unviewed, ai_trainer_activities(:johns_full_review)
    assert_not_includes unviewed, ai_trainer_activities(:johns_pending_activity)
  end

  test "viewed? returns true when viewed_at is present" do
    activity = ai_trainer_activities(:johns_workout_review)
    activity.viewed_at = Time.current
    assert activity.viewed?
  end

  test "viewed? returns false when viewed_at is nil" do
    activity = ai_trainer_activities(:johns_workout_review)
    activity.viewed_at = nil
    refute activity.viewed?
  end
end
