class GenerateAiWorkoutFeedbackJob < ApplicationJob
  queue_as :default

  def perform(workout:)
    return if workout.ai_trainer_activity&.completed?

    user = workout.user
    ai_trainer = user.ai_trainer
    return unless ai_trainer

    activity =
      workout.ai_trainer_activity ||
        AiTrainerActivity.new(
          user:,
          ai_trainer:,
          workout:,
          activity_type: :workout_review
        )

    result = AiWorkoutFeedbackService.new(workout).call

    activity.update!(content: result, status: :completed)

    # Also write to workout.ai_summary during transition
    workout.update!(ai_summary: result)
  rescue => e
    if activity&.persisted?
      activity&.update(status: :failed, error_message: e.message)
    end
    Rails.logger.error(
      "AI workout feedback failed for workout ##{workout.id}: #{e.message}"
    )
  end
end
