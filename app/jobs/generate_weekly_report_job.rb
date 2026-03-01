# frozen_string_literal: true

class GenerateWeeklyReportJob < ApplicationJob
  queue_as :default

  COMPACTION_THRESHOLD = 4

  def perform(user:, week_start:)
    ai_trainer = user.ai_trainer
    return unless ai_trainer

    # Keep legacy weekly_reports in sync during transition
    report = user.weekly_reports.find_or_create_by!(week_start: week_start)
    return if report.completed?

    report.pending!

    activity =
      ai_trainer.ai_trainer_activities.create!(
        user:,
        activity_type: :weekly_report,
        week_start: week_start,
        status: :pending
      )

    response = AiWeeklyReportService.new(user, week_start).call

    activity.update!(content: response, status: :completed)
    report.update!(ai_summary: response, status: :completed)

    append_recommendations(user, response)
  rescue => e
    activity&.update(status: :failed, error_message: e.message)
    report&.update(status: :failed, error_message: e.message)
    Rails.logger.error("Weekly report failed for user #{user.id}: #{e.message}")
  end

  private

  def append_recommendations(user, response)
    week_section = response[/## Week of .*/m]
    return unless week_section

    ai_trainer = user.ai_trainer
    return unless ai_trainer

    ai_trainer.update!(
      system_prompt: "#{ai_trainer.system_prompt}\n\n#{week_section}"
    )

    compact_prompt_if_needed(ai_trainer)
  end

  def compact_prompt_if_needed(ai_trainer)
    weekly_sections = ai_trainer.system_prompt.scan(/## Week /).size
    return unless weekly_sections >= COMPACTION_THRESHOLD

    AiTrainerPromptCompactor.new(ai_trainer).call
  end
end
