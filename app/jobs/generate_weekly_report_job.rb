# frozen_string_literal: true

class GenerateWeeklyReportJob < ApplicationJob
  queue_as :default

  def perform(user:, week_start:)
    report = user.weekly_reports.find_or_create_by!(week_start: week_start)
    return if report.completed?

    report.pending!

    response = AiWeeklyReportService.new(user, week_start).call

    report.update!(ai_summary: response, status: :completed)

    append_recommendations(user, response)
  rescue => e
    report&.update(status: :failed, error_message: e.message)
    Rails.logger.error("Weekly report failed for user #{user.id}: #{e.message}")
  end

  private

  def append_recommendations(user, response)
    ai_trainer = user.ai_trainer
    return unless ai_trainer

    recommendations = extract_recommendations(response)
    return if recommendations.blank?

    updated_prompt = [ai_trainer.system_prompt, recommendations].compact.join(
      "\n\n"
    )
    ai_trainer.update!(system_prompt: updated_prompt)
  end

  def extract_recommendations(response)
    match = response.match(/^(## Week .+)/m)
    match&.[](1)
  end
end
