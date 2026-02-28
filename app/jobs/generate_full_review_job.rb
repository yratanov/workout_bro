class GenerateFullReviewJob < ApplicationJob
  queue_as :default

  def perform(ai_trainer:)
    user = ai_trainer.user

    activity =
      ai_trainer.ai_trainer_activities.create!(
        user:,
        activity_type: :full_review,
        status: :pending
      )

    has_recent_activities = ai_trainer.activities_since_last_review.exists?

    result =
      if has_recent_activities
        AiCompactionService.new(ai_trainer).call
      else
        AiHistoryReviewService.new(ai_trainer).call
      end

    activity.update!(content: result, status: :completed)
  rescue => e
    activity&.update(status: :failed, error_message: e.message)
    Rails.logger.error(
      "Full review failed for trainer ##{ai_trainer.id}: #{e.message}"
    )
  end
end
