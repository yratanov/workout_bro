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
  end

  test "creates a completed activity" do
    VCR.use_cassette("jobs/workout_feedback/streaming") do
      GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)
    end

    activity = @workout.reload.ai_trainer_activity
    assert activity.completed?
    assert_equal "Great workout!", activity.content
  end

  test "triggers compaction when conversation exceeds token threshold" do
    AiConversationBuilder.any_instance.stubs(:compaction_needed?).returns(true)

    assert_enqueued_with(job: GenerateFullReviewJob) do
      VCR.use_cassette("jobs/workout_feedback/streaming") do
        GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)
      end
    end
  end

  test "does not trigger compaction when under threshold" do
    VCR.use_cassette("jobs/workout_feedback/streaming") do
      GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)
    end

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

    Turbo::StreamsChannel.stubs(:broadcast_replace_to)

    VCR.use_cassette("jobs/workout_feedback/simple") do
      GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)
    end

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

    VCR.use_cassette("jobs/workout_feedback/error") do
      GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)
    end

    activity.reload
    assert activity.failed?
    assert_not_nil activity.error_message
  end

  test "creates new activity if workout does not have one yet" do
    assert_nil @workout.ai_trainer_activity

    assert_difference "AiTrainerActivity.count", 1 do
      VCR.use_cassette("jobs/workout_feedback/new_feedback") do
        GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)
      end
    end

    activity = @workout.reload.ai_trainer_activity
    assert activity.completed?
    assert_equal "New feedback", activity.content
    assert_equal "workout_review", activity.activity_type
  end

  test "broadcasts feedback when trainer is not configured" do
    @ai_trainer.update!(status: :pending, trainer_profile: nil)

    Turbo::StreamsChannel
      .expects(:broadcast_replace_to)
      .with(
        [@workout, :ai_feedback],
        target: "ai_feedback_content_#{@workout.id}",
        html: anything
      )
      .at_least_once

    VCR.use_cassette("jobs/workout_feedback/simple") do
      GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)
    end
  end

  test "streaming path creates completed activity with content" do
    VCR.use_cassette("jobs/workout_feedback/broadcast") do
      GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)
    end

    activity = @workout.reload.ai_trainer_activity
    assert activity.completed?
    assert_equal "Streaming feedback", activity.content
  end

  test "extracts suggestions from AI response and stores them" do
    @workout.update!(workout_routine_day: workout_routine_days(:push_day))
    job = GenerateAiWorkoutFeedbackJob.new

    result_with_suggestions =
      "Good session overall.\n\n<!--SUGGESTIONS:[{\"exercise\":\"Bench Press\",\"field\":\"sets\",\"value\":\"4\",\"reason\":\"You completed all sets easily\"}]-->"

    content, suggestions =
      job.send(:extract_suggestions, result_with_suggestions, @workout)

    assert_equal "Good session overall.", content
    assert_equal 1, suggestions.length
    assert_equal "Bench Press", suggestions[0]["exercise"]
    assert_equal "sets", suggestions[0]["field"]
    assert_equal "4", suggestions[0]["value"]
    assert_equal workout_routine_day_exercises(:push_day_bench).id,
                 suggestions[0]["workout_routine_day_exercise_id"]
  end

  test "returns content without suggestions when no tag present" do
    job = GenerateAiWorkoutFeedbackJob.new

    content, suggestions =
      job.send(:extract_suggestions, "Just feedback.", @workout)

    assert_equal "Just feedback.", content
    assert_nil suggestions
  end

  test "handles malformed JSON in suggestions tag gracefully" do
    job = GenerateAiWorkoutFeedbackJob.new

    content, suggestions =
      job.send(
        :extract_suggestions,
        "Good.\n\n<!--SUGGESTIONS:not json-->",
        @workout
      )

    assert_equal "Good.", content
    assert_nil suggestions
  end

  test "error handling does not update activity when not persisted" do
    assert_nil @workout.ai_trainer_activity

    VCR.use_cassette("jobs/workout_feedback/error") do
      GenerateAiWorkoutFeedbackJob.new.perform(workout: @workout)
    end

    assert_nil @workout.reload.ai_trainer_activity
  end
end
