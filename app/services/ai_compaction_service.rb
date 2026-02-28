# frozen_string_literal: true

class AiCompactionService
  MAX_ACTIVITY_CONTENT_LENGTH = 500

  def initialize(ai_trainer)
    @ai_trainer = ai_trainer
    @user = ai_trainer.user
  end

  def call
    client = GeminiClient.new(api_key: @user.ai_api_key, model: @user.ai_model)
    client.generate(
      build_prompt,
      log_context: {
        user: @user,
        action: "full_review_compaction"
      }
    )
  end

  private

  def build_prompt
    sections = [
      trainer_profile_section,
      previous_review_section,
      recent_activities_section,
      instruction_section
    ]
    sections.compact.join("\n\n")
  end

  def trainer_profile_section
    return nil if @ai_trainer.trainer_profile.blank?

    <<~PROMPT.strip
      ## Trainer Profile
      #{@ai_trainer.trainer_profile}
    PROMPT
  end

  def previous_review_section
    review = @ai_trainer.latest_full_review
    return nil unless review

    <<~PROMPT.strip
      ## Previous Training Review
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
        date = a.created_at.strftime("%-d %b %Y")
        "### #{label} (#{date})\n#{content}"
      end

    <<~PROMPT.strip
      ## Activities Since Last Review
      #{entries.join("\n\n")}
    PROMPT
  end

  def instruction_section
    <<~PROMPT.strip
      ## Task
      Generate an updated comprehensive training review that incorporates the previous review
      and all recent activities. This replaces the previous review as the new baseline. Include:
      1. Updated training patterns and progress assessment
      2. What's going well — improvements and consistency
      3. Current areas for improvement
      4. Updated personalized recommendations

      Keep your response under 500 words. Use markdown formatting.
      Respond in #{@user.locale == "ru" ? "Russian" : "English"}.
    PROMPT
  end
end
