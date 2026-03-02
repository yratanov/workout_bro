# frozen_string_literal: true

module AiCompactionTrigger
  private

  def trigger_compaction_if_needed(ai_trainer)
    return unless AiConversationBuilder.new(ai_trainer).compaction_needed?

    GenerateFullReviewJob.perform_later(ai_trainer:)
  end
end
