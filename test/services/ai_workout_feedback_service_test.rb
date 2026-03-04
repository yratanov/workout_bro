require "test_helper"

class AiWorkoutFeedbackServiceTest < ActiveSupport::TestCase
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
      trainer_profile: "A motivational trainer profile."
    )
    @workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )
  end

  test "calls generate_chat with conversation messages when trainer is configured" do
    workout_set =
      @workout.workout_sets.create!(
        exercise: exercises(:bench_press),
        started_at: 30.minutes.ago
      )
    workout_set.workout_reps.create!(weight: 100, reps: 10)

    VCR.use_cassette("ai_workout_feedback/chat") do
      result = AiWorkoutFeedbackService.new(@workout).call
      assert_equal "Great workout!", result
    end
  end

  test "falls back to generate for unconfigured trainer" do
    @ai_trainer.update!(status: :pending)

    VCR.use_cassette("ai_workout_feedback/simple") do
      result = AiWorkoutFeedbackService.new(@workout).call
      assert_equal "Basic feedback", result
    end
  end

  test "includes run details in the last message for run workout" do
    run_workout =
      Workout.create!(
        user: @user,
        workout_type: :run,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        distance: 5000,
        time_in_seconds: 1800
      )

    VCR.use_cassette("ai_workout_feedback/run") do
      result = AiWorkoutFeedbackService.new(run_workout).call
      assert_equal "Nice run!", result
    end
  end

  test "prompt includes workout data for strength workout" do
    workout_set =
      @workout.workout_sets.create!(
        exercise: exercises(:bench_press),
        started_at: 30.minutes.ago
      )
    workout_set.workout_reps.create!(weight: 100, reps: 10)

    service = AiWorkoutFeedbackService.new(@workout)
    prompt = service.prompt

    assert_includes prompt, "Strength"
    assert_includes prompt, "Bench Press"
    assert_includes prompt, "100"
  end

  test "prompt includes run details for run workout" do
    run_workout =
      Workout.create!(
        user: @user,
        workout_type: :run,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        distance: 5000,
        time_in_seconds: 1800
      )

    service = AiWorkoutFeedbackService.new(run_workout)
    prompt = service.prompt

    assert_includes prompt, "Run"
    assert_includes prompt, "5.0km"
  end
end
