# frozen_string_literal: true

class ExtractAiMemoriesJob < ApplicationJob
  queue_as :default

  def perform(activity:)
    return unless activity.completed? && activity.content.present?

    user = activity.user
    return unless user.ai_configured?

    AiMemoryExtractionService.new(
      user: user,
      activity_content: activity.content
    ).call
  rescue => e
    Rails.logger.error(
      "AI memory extraction failed for activity ##{activity.id}: #{e.message}"
    )
  end
end
