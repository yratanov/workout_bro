# frozen_string_literal: true

class AiPromptContextBuilder
  MAX_ACTIVITY_CONTENT_LENGTH = 500

  def initialize(ai_trainer)
    @ai_trainer = ai_trainer
  end

  def call
    sections = [
      static_instructions,
      trainer_profile_section,
      full_review_section,
      recent_activities_section
    ]
    sections.compact.join("\n\n")
  end

  private

  def static_instructions
    <<~PROMPT.strip
      You are a personal fitness trainer AI assistant. Your role is to help the user with their
      workout planning, form guidance, exercise selection, and motivation. Always prioritize safety
      and proper form. If the user describes pain or injury symptoms, recommend consulting a
      healthcare professional.
    PROMPT
  end

  def trainer_profile_section
    return nil if @ai_trainer.trainer_profile.blank?

    <<~PROMPT.strip
      ## Your Trainer Profile
      #{@ai_trainer.trainer_profile}
    PROMPT
  end

  def full_review_section
    review = @ai_trainer.latest_full_review
    return nil unless review

    <<~PROMPT.strip
      ## Latest Training Review
      #{review.content}
    PROMPT
  end

  def recent_activities_section
    activities = @ai_trainer.activities_since_last_review
    return nil if activities.empty?

    entries =
      activities.map do |a|
        content = a.content.to_s.truncate(MAX_ACTIVITY_CONTENT_LENGTH)
        label = a.activity_type.humanize
        "- [#{label}] #{content}"
      end

    <<~PROMPT.strip
      ## Recent Activity Context
      #{entries.join("\n")}
    PROMPT
  end
end
