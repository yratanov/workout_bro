require "test_helper"

class AiHistoryReviewServiceTest < ActiveSupport::TestCase
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
      trainer_profile: "A motivational fitness trainer."
    )
  end

  test "calls AI client and returns result" do
    mock_client = mock("AiClient")
    AiClient.stubs(:for).returns(mock_client)
    mock_client
      .expects(:generate)
      .with do |prompt|
        prompt.include?("Trainer Profile") &&
          prompt.include?("comprehensive training review")
      end
      .returns("Training review content")

    result = AiHistoryReviewService.new(@ai_trainer).call
    assert_equal "Training review content", result
  end

  test "includes workout data when available" do
    workout =
      @user.workouts.create!(
        workout_type: :strength,
        started_at: 1.day.ago,
        ended_at: Time.current,
        date: Date.current
      )
    exercise =
      @user.exercises.first || @user.exercises.create!(name: "Bench Press")
    ws =
      workout.workout_sets.create!(
        exercise: exercise,
        started_at: 1.day.ago,
        ended_at: Time.current
      )
    ws.workout_reps.create!(reps: 10, weight: 60)

    mock_client = mock("AiClient")
    AiClient.stubs(:for).returns(mock_client)
    mock_client
      .expects(:generate)
      .with { |prompt| prompt.include?("Workout History") }
      .returns("Review")

    AiHistoryReviewService.new(@ai_trainer).call
  end
end
