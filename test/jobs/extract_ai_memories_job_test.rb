require "test_helper"

class ExtractAiMemoriesJobTest < ActiveJob::TestCase
  setup do
    @user = users(:john)
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
  end

  test "calls extraction service for completed activity" do
    activity = ai_trainer_activities(:johns_workout_review)

    AiMemoryExtractionService.any_instance.expects(:call).once

    ExtractAiMemoriesJob.perform_now(activity: activity)
  end

  test "skips non-completed activities" do
    activity = ai_trainer_activities(:johns_pending_activity)

    AiMemoryExtractionService.any_instance.expects(:call).never

    ExtractAiMemoriesJob.perform_now(activity: activity)
  end

  test "skips activities without content" do
    activity = ai_trainer_activities(:johns_workout_review)
    activity.update_column(:content, nil)

    AiMemoryExtractionService.any_instance.expects(:call).never

    ExtractAiMemoriesJob.perform_now(activity: activity)
  end

  test "rescues and logs errors" do
    activity = ai_trainer_activities(:johns_workout_review)

    AiMemoryExtractionService
      .any_instance
      .stubs(:call)
      .raises(StandardError, "API error")

    assert_nothing_raised do
      ExtractAiMemoriesJob.perform_now(activity: activity)
    end
  end

  test "skips when user has no AI configured" do
    activity = ai_trainer_activities(:johns_workout_review)
    @user.update_columns(ai_provider: nil, ai_model: nil, ai_api_key: nil)

    AiMemoryExtractionService.any_instance.expects(:call).never

    ExtractAiMemoriesJob.perform_now(activity: activity)
  end
end
