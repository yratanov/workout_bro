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
  end

  test "creates a full_review activity" do
    assert_difference "AiTrainerActivity.full_review.count", 1 do
      VCR.use_cassette("jobs/full_review/initial") do
        GenerateFullReviewJob.new.perform(ai_trainer: @ai_trainer)
      end
    end

    activity = AiTrainerActivity.full_review.last
    assert_equal "Full review content", activity.content
    assert activity.completed?
    assert_equal @user, activity.user
  end

  test "uses AiCompactionService when recent activities exist" do
    VCR.use_cassette("jobs/full_review/compaction") do
      GenerateFullReviewJob.new.perform(ai_trainer: @ai_trainer)
    end

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
    VCR.use_cassette("jobs/full_review/error") do
      assert_nothing_raised do
        GenerateFullReviewJob.new.perform(ai_trainer: @ai_trainer)
      end
    end

    activity = AiTrainerActivity.full_review.order(created_at: :desc).first
    assert activity.failed?
    assert_not_nil activity.error_message
  end
end
