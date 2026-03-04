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
    VCR.use_cassette("ai_history_review/generate") do
      result = AiHistoryReviewService.new(@ai_trainer).call
      assert_equal "Training review content", result
    end
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

    VCR.use_cassette("ai_history_review/with_data") do
      result = AiHistoryReviewService.new(@ai_trainer).call
      assert_equal "Review", result
    end
  end
end
