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

    mock_client = mock("AiClient")
    AiClient.stubs(:for).with(@user).returns(mock_client)
    mock_client
      .expects(:generate_chat)
      .with do |messages, **opts|
        messages.is_a?(Array) &&
          opts[:system_instruction].include?(
            "A motivational trainer profile."
          ) && messages.last[:role] == "user" &&
          messages.last[:text].include?("Strength") &&
          messages.last[:text].include?("Bench Press") &&
          messages.last[:text].include?("100")
      end
      .returns("Great workout!")

    result = AiWorkoutFeedbackService.new(@workout).call
    assert_equal "Great workout!", result
  end

  test "includes trainer context in system_instruction" do
    mock_client = mock("AiClient")
    AiClient.stubs(:for).returns(mock_client)
    mock_client
      .expects(:generate_chat)
      .with do |_messages, **opts|
        opts[:system_instruction].include?("A motivational trainer profile.")
      end
      .returns("Feedback")

    AiWorkoutFeedbackService.new(@workout).call
  end

  test "falls back to generate for unconfigured trainer" do
    @ai_trainer.update!(status: :pending)

    mock_client = mock("AiClient")
    AiClient.stubs(:for).returns(mock_client)
    mock_client.expects(:generate).returns("Basic feedback")

    result = AiWorkoutFeedbackService.new(@workout).call
    assert_equal "Basic feedback", result
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

    mock_client = mock("AiClient")
    AiClient.stubs(:for).returns(mock_client)
    mock_client
      .expects(:generate_chat)
      .with do |messages, **|
        last_msg = messages.last
        last_msg[:text].include?("Run") && last_msg[:text].include?("5.0km")
      end
      .returns("Nice run!")

    result = AiWorkoutFeedbackService.new(run_workout).call
    assert_equal "Nice run!", result
  end
end
