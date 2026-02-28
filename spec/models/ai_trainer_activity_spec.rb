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
#  ai_trainer_id :integer          not null
#  user_id       :integer          not null
#  workout_id    :integer
#
# Indexes
#
#  idx_activities_trainer_type_created                       (ai_trainer_id,activity_type,created_at)
#  index_ai_trainer_activities_on_ai_trainer_id              (ai_trainer_id)
#  index_ai_trainer_activities_on_user_id                    (user_id)
#  index_ai_trainer_activities_on_user_id_and_activity_type  (user_id,activity_type)
#  index_ai_trainer_activities_on_user_id_and_created_at     (user_id,created_at)
#  index_ai_trainer_activities_on_workout_id                 (workout_id)
#
# Foreign Keys
#
#  ai_trainer_id  (ai_trainer_id => ai_trainers.id) ON DELETE => cascade
#  user_id        (user_id => users.id)
#  workout_id     (workout_id => workouts.id) ON DELETE => nullify
#
describe AiTrainerActivity do
  fixtures :all

  let(:activity) { ai_trainer_activities(:johns_workout_review) }

  describe "enums" do
    it "defines activity_type enum" do
      expect(AiTrainerActivity.activity_types).to eq(
        "full_review" => 0,
        "workout_review" => 1,
        "weekly_report" => 2
      )
    end

    it "defines status enum" do
      expect(AiTrainerActivity.statuses).to eq(
        "pending" => 0,
        "completed" => 1,
        "failed" => 2
      )
    end
  end

  describe "associations" do
    it "belongs to user" do
      expect(activity.user).to eq(users(:john))
    end

    it "belongs to ai_trainer" do
      expect(activity.ai_trainer).to eq(ai_trainers(:johns_trainer))
    end

    it "optionally belongs to workout" do
      expect(activity.workout).to eq(workouts(:completed_workout))
      report = ai_trainer_activities(:johns_weekly_report)
      expect(report.workout).to be_nil
    end
  end

  describe "scopes" do
    it "recent orders by created_at desc" do
      activities = AiTrainerActivity.recent
      expect(activities.first.created_at).to be >= activities.last.created_at
    end

    it "unviewed returns completed activities without viewed_at" do
      unviewed = users(:john).ai_trainer_activities.unviewed
      expect(unviewed).to include(ai_trainer_activities(:johns_workout_review))
      expect(unviewed).to include(ai_trainer_activities(:johns_unviewed_report))
      expect(unviewed).not_to include(ai_trainer_activities(:johns_full_review))
      expect(unviewed).not_to include(
        ai_trainer_activities(:johns_pending_activity)
      )
    end
  end

  describe "#viewed?" do
    it "returns true when viewed_at is present" do
      activity.viewed_at = Time.current
      expect(activity.viewed?).to be true
    end

    it "returns false when viewed_at is nil" do
      activity.viewed_at = nil
      expect(activity.viewed?).to be false
    end
  end
end
