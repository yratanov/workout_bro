# frozen_string_literal: true

class GenerateWeeklyReportJob < ApplicationJob
  include AiCompactionTrigger

  queue_as :default

  def perform(user:, week_start:)
    ai_trainer = user.ai_trainer
    return unless ai_trainer

    activity =
      ai_trainer.ai_trainer_activities.create!(
        user:,
        activity_type: :weekly_report,
        week_start: week_start,
        status: :pending
      )

    response = AiWeeklyReportService.new(user, week_start).call

    activity.update!(content: response, status: :completed)

    trigger_compaction_if_needed(ai_trainer)
  rescue => e
    activity&.update(status: :failed, error_message: e.message)
    Rails.logger.error("Weekly report failed for user #{user.id}: #{e.message}")
  end
end
