require "test_helper"

class GenerateAiFollowupJobTest < ActiveJob::TestCase
  setup do
    @user = users(:john)
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
    @ai_trainer = @user.ai_trainer
    @ai_trainer.update!(status: :completed, trainer_profile: "Test profile")

    @workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )

    @activity =
      AiTrainerActivity.create!(
        user: @user,
        ai_trainer: @ai_trainer,
        workout: @workout,
        activity_type: :workout_review,
        status: :completed,
        content: "Great workout!"
      )
  end

  test "creates user and assistant messages" do
    VCR.use_cassette("jobs/followup/basic") do
      GenerateAiFollowupJob.perform_now(
        activity: @activity,
        question: "Should I increase weight?"
      )
    end

    messages = @activity.ai_trainer_messages.order(:created_at)
    assert_equal 2, messages.count
    assert messages.first.user?
    assert_equal "Should I increase weight?", messages.first.content
    assert messages.last.assistant?
    assert messages.last.content.present?
  end

  test "includes previous followup messages in conversation" do
    @activity.ai_trainer_messages.create!(
      role: :user,
      content: "First question"
    )
    @activity.ai_trainer_messages.create!(
      role: :assistant,
      content: "First answer"
    )

    VCR.use_cassette("jobs/followup/with_history") do
      GenerateAiFollowupJob.perform_now(
        activity: @activity,
        question: "Follow up question"
      )
    end

    messages = @activity.ai_trainer_messages.order(:created_at)
    assert_equal 4, messages.count
    assert_equal "Follow up question", messages.third.content
    assert messages.last.assistant?
  end

  test "skips when trainer is not configured" do
    @ai_trainer.update!(status: :pending, trainer_profile: nil)

    GenerateAiFollowupJob.perform_now(
      activity: @activity,
      question: "Test question"
    )

    assert_equal 0, @activity.ai_trainer_messages.count
  end

  test "broadcasts response via turbo streams" do
    Turbo::StreamsChannel.expects(:broadcast_replace_to).at_least_once

    VCR.use_cassette("jobs/followup/broadcast") do
      GenerateAiFollowupJob.perform_now(
        activity: @activity,
        question: "How was my form?"
      )
    end
  end
end
