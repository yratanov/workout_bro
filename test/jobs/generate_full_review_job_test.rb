require "test_helper"

class GenerateFullReviewJobTest < ActiveJob::TestCase
  setup do
    @user = users(:john)
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )

    @ai_trainer = @user.ai_trainer
    @ai_trainer.update!(
      status: :completed,
      trainer_profile: "A balanced fitness trainer."
    )

    @mock_client = mock("ai_client")
    @mock_client.stubs(:generate).returns("Full review content")
    @mock_client.stubs(:generate_chat).returns("Full review content")
    AiClient.stubs(:for).returns(@mock_client)
  end

  test "creates a full_review activity" do
    assert_difference "AiTrainerActivity.full_review.count", 1 do
      GenerateFullReviewJob.new.perform(ai_trainer: @ai_trainer)
    end

    activity = AiTrainerActivity.full_review.last
    assert_equal "Full review content", activity.content
    assert activity.completed?
    assert_equal @user, activity.user
  end

  test "uses AiCompactionService when recent activities exist" do
    @mock_client.stubs(:generate_chat).returns("Compacted")

    GenerateFullReviewJob.new.perform(ai_trainer: @ai_trainer)

    activity = AiTrainerActivity.full_review.order(created_at: :desc).first
    assert_equal "Compacted", activity.content
  end

  test "skips when a full_review was created within the last hour" do
    @ai_trainer.ai_trainer_activities.create!(
      user: @user,
      activity_type: :full_review,
      status: :completed,
      content: "Recent review"
    )

    assert_no_difference "AiTrainerActivity.full_review.count" do
      GenerateFullReviewJob.new.perform(ai_trainer: @ai_trainer)
    end
  end

  test "handles errors gracefully" do
    @mock_client.stubs(:generate_chat).raises(StandardError, "API error")
    @mock_client.stubs(:generate).raises(StandardError, "API error")

    assert_nothing_raised do
      GenerateFullReviewJob.new.perform(ai_trainer: @ai_trainer)
    end

    activity = AiTrainerActivity.full_review.order(created_at: :desc).first
    assert activity.failed?
    assert_includes activity.error_message, "API error"
  end
end
