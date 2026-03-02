require "test_helper"

class GenerateAiWorkoutFeedbackJobTest < ActiveJob::TestCase
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

    @workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current
      )

    @mock_conversation = {
      system_instruction: "You are a trainer.",
      messages: []
    }
  end

  test "creates a completed activity" do
    mock_service = mock("feedback_service")
    mock_service.stubs(:call).returns("Great workout!")
    mock_service.stubs(:request_message).returns("Workout data")
    AiWorkoutFeedbackService.stubs(:new).returns(mock_service)

    mock_builder = mock("conversation_builder")
    mock_builder.stubs(:build).returns(@mock_conversation)
    mock_builder.stubs(:compaction_needed?).returns(false)
    AiConversationBuilder.stubs(:new).returns(mock_builder)

    mock_client = mock("ai_client")
    mock_client.stubs(:generate_chat_stream).returns("Great workout!")
    AiClient.stubs(:for).returns(mock_client)

    GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)

    activity = @workout.reload.ai_trainer_activity
    assert activity.completed?
    assert_equal "Great workout!", activity.content
  end

  test "triggers compaction when conversation exceeds token threshold" do
    mock_service = mock("feedback_service")
    mock_service.stubs(:call).returns("Feedback")
    mock_service.stubs(:request_message).returns("Workout data")
    AiWorkoutFeedbackService.stubs(:new).returns(mock_service)

    mock_builder = mock("conversation_builder")
    mock_builder.stubs(:build).returns(@mock_conversation)
    mock_builder.stubs(:compaction_needed?).returns(true)
    AiConversationBuilder.stubs(:new).returns(mock_builder)

    mock_client = mock("ai_client")
    mock_client.stubs(:generate_chat_stream).returns("Feedback")
    AiClient.stubs(:for).returns(mock_client)

    assert_enqueued_with(job: GenerateFullReviewJob) do
      GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)
    end
  end

  test "does not trigger compaction when under threshold" do
    mock_service = mock("feedback_service")
    mock_service.stubs(:call).returns("Feedback")
    mock_service.stubs(:request_message).returns("Workout data")
    AiWorkoutFeedbackService.stubs(:new).returns(mock_service)

    mock_builder = mock("conversation_builder")
    mock_builder.stubs(:build).returns(@mock_conversation)
    mock_builder.stubs(:compaction_needed?).returns(false)
    AiConversationBuilder.stubs(:new).returns(mock_builder)

    mock_client = mock("ai_client")
    mock_client.stubs(:generate_chat_stream).returns("Feedback")
    AiClient.stubs(:for).returns(mock_client)

    GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)

    assert_enqueued_jobs 0, only: GenerateFullReviewJob
  end

  test "skips if activity is already completed" do
    AiTrainerActivity.create!(
      user: @user,
      ai_trainer: @ai_trainer,
      workout: @workout,
      activity_type: :workout_review,
      status: :completed,
      content: "Already done"
    )

    AiWorkoutFeedbackService.expects(:new).never

    GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)
  end

  test "falls back to simple call when trainer is not configured" do
    @ai_trainer.update!(status: :pending, trainer_profile: nil)

    mock_service = mock("feedback_service")
    mock_service.expects(:call).returns("Simple feedback")
    AiWorkoutFeedbackService.stubs(:new).returns(mock_service)

    mock_builder = mock("conversation_builder")
    mock_builder.stubs(:compaction_needed?).returns(false)
    AiConversationBuilder.stubs(:new).returns(mock_builder)

    Turbo::StreamsChannel.stubs(:broadcast_replace_to)

    GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)

    activity = @workout.reload.ai_trainer_activity
    assert activity.completed?
    assert_equal "Simple feedback", activity.content
  end

  test "returns early when user has no ai_trainer" do
    @ai_trainer.destroy!
    @workout.reload

    AiWorkoutFeedbackService.expects(:new).never

    GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)

    assert_nil @workout.reload.ai_trainer_activity
  end

  test "sets activity to failed status on error" do
    activity =
      AiTrainerActivity.create!(
        user: @user,
        ai_trainer: @ai_trainer,
        workout: @workout,
        activity_type: :workout_review,
        status: :pending
      )

    mock_service = mock("feedback_service")
    mock_service.stubs(:request_message).returns("Workout data")
    AiWorkoutFeedbackService.stubs(:new).returns(mock_service)

    mock_builder = mock("conversation_builder")
    mock_builder.stubs(:build).returns(@mock_conversation)
    AiConversationBuilder.stubs(:new).returns(mock_builder)

    mock_client = mock("ai_client")
    mock_client.stubs(:generate_chat_stream).raises(
      StandardError,
      "API connection failed"
    )
    AiClient.stubs(:for).returns(mock_client)

    GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)

    activity.reload
    assert activity.failed?
    assert_equal "API connection failed", activity.error_message
  end

  test "creates new activity if workout does not have one yet" do
    assert_nil @workout.ai_trainer_activity

    mock_service = mock("feedback_service")
    mock_service.stubs(:call).returns("New feedback")
    mock_service.stubs(:request_message).returns("Workout data")
    AiWorkoutFeedbackService.stubs(:new).returns(mock_service)

    mock_builder = mock("conversation_builder")
    mock_builder.stubs(:build).returns(@mock_conversation)
    mock_builder.stubs(:compaction_needed?).returns(false)
    AiConversationBuilder.stubs(:new).returns(mock_builder)

    mock_client = mock("ai_client")
    mock_client.stubs(:generate_chat_stream).returns("New feedback")
    AiClient.stubs(:for).returns(mock_client)

    assert_difference "AiTrainerActivity.count", 1 do
      GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)
    end

    activity = @workout.reload.ai_trainer_activity
    assert activity.completed?
    assert_equal "New feedback", activity.content
    assert_equal "workout_review", activity.activity_type
  end

  test "broadcasts feedback when trainer is not configured" do
    @ai_trainer.update!(status: :pending, trainer_profile: nil)

    mock_service = mock("feedback_service")
    mock_service.expects(:call).returns("Simple feedback")
    AiWorkoutFeedbackService.stubs(:new).returns(mock_service)

    mock_builder = mock("conversation_builder")
    mock_builder.stubs(:compaction_needed?).returns(false)
    AiConversationBuilder.stubs(:new).returns(mock_builder)

    Turbo::StreamsChannel
      .expects(:broadcast_replace_to)
      .with(
        [@workout, :ai_feedback],
        target: "ai_feedback_content_#{@workout.id}",
        html: anything
      )
      .once

    GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)
  end

  test "streaming path broadcasts feedback via Turbo::StreamsChannel" do
    mock_service = mock("feedback_service")
    mock_service.stubs(:request_message).returns("Workout data")
    AiWorkoutFeedbackService.stubs(:new).returns(mock_service)

    mock_builder = mock("conversation_builder")
    mock_builder.stubs(:build).returns(@mock_conversation)
    mock_builder.stubs(:compaction_needed?).returns(false)
    AiConversationBuilder.stubs(:new).returns(mock_builder)

    # Create a fake client that yields to the block with a sleep to ensure
    # the throttle window (150ms) passes
    fake_client =
      Object.new.tap do |c|
        def c.generate_chat_stream(*_args, **_opts)
          sleep 0.2 # exceed the 150ms throttle window
          yield "Streaming feedback" if block_given?
          "Streaming feedback"
        end
      end
    AiClient.stubs(:for).returns(fake_client)

    Turbo::StreamsChannel
      .expects(:broadcast_replace_to)
      .with(
        [@workout, :ai_feedback],
        target: "ai_feedback_content_#{@workout.id}",
        html: anything
      )
      .at_least_once

    GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)

    activity = @workout.reload.ai_trainer_activity
    assert activity.completed?
    assert_equal "Streaming feedback", activity.content
  end

  test "error handling does not update activity when not persisted" do
    mock_service = mock("feedback_service")
    mock_service.stubs(:request_message).returns("Workout data")
    AiWorkoutFeedbackService.stubs(:new).returns(mock_service)

    mock_builder = mock("conversation_builder")
    mock_builder.stubs(:build).returns(@mock_conversation)
    AiConversationBuilder.stubs(:new).returns(mock_builder)

    mock_client = mock("ai_client")
    mock_client.stubs(:generate_chat_stream).raises(StandardError, "API failed")
    AiClient.stubs(:for).returns(mock_client)

    # No pre-existing activity, so the new AiTrainerActivity is not persisted
    # when the error occurs during generate_with_streaming
    assert_nil @workout.ai_trainer_activity

    # Should not raise and should not create a failed activity record
    GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)

    # The activity was never persisted, so it should not exist
    assert_nil @workout.reload.ai_trainer_activity
  end
end
