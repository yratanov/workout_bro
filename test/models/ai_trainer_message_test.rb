# == Schema Information
#
# Table name: ai_trainer_messages
# Database name: primary
#
#  id                     :integer          not null, primary key
#  content                :text             not null
#  role                   :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  ai_trainer_activity_id :integer          not null
#
# Indexes
#
#  index_ai_trainer_messages_on_ai_trainer_activity_id  (ai_trainer_activity_id)
#
# Foreign Keys
#
#  ai_trainer_activity_id  (ai_trainer_activity_id => ai_trainer_activities.id)
#
require "test_helper"

class AiTrainerMessageTest < ActiveSupport::TestCase
  test "valid message" do
    message =
      AiTrainerMessage.new(
        ai_trainer_activity: ai_trainer_activities(:johns_workout_review),
        role: :user,
        content: "How should I improve?"
      )
    assert message.valid?
  end

  test "requires content" do
    message =
      AiTrainerMessage.new(
        ai_trainer_activity: ai_trainer_activities(:johns_workout_review),
        role: :user,
        content: nil
      )
    assert_not message.valid?
  end

  test "requires role" do
    message =
      AiTrainerMessage.new(
        ai_trainer_activity: ai_trainer_activities(:johns_workout_review),
        role: nil,
        content: "test"
      )
    assert_not message.valid?
  end

  test "user and assistant roles" do
    assert AiTrainerMessage.new(role: :user).user?
    assert AiTrainerMessage.new(role: :assistant).assistant?
  end

  test "activity has many messages" do
    activity = ai_trainer_activities(:johns_workout_review)
    assert activity.ai_trainer_messages.count >= 2
  end
end
