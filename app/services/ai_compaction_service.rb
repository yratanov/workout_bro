# frozen_string_literal: true

class AiCompactionService
  def initialize(ai_trainer)
    @ai_trainer = ai_trainer
    @user = ai_trainer.user
  end

  def call
    client = GeminiClient.new(api_key: @user.ai_api_key, model: @user.ai_model)
    messages = AiConversationBuilder.new(@ai_trainer).build
    messages << { role: "user", text: instruction_text }
    client.generate_chat(
      messages,
      log_context: {
        user: @user,
        action: "full_review_compaction"
      }
    )
  end

  private

  def instruction_text
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
