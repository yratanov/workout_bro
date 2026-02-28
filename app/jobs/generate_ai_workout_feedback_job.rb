class GenerateAiWorkoutFeedbackJob < ApplicationJob
  queue_as :default

  def perform(workout:)
    return if workout.ai_summary.present?

    result = AiWorkoutFeedbackService.new(workout).call
    workout.update!(ai_summary: result)
  rescue => e
    Rails.logger.error(
      "AI workout feedback failed for workout ##{workout.id}: #{e.message}"
    )
  end
end
