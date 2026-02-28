# frozen_string_literal: true

class AiTrainerPromptCompactor
  COMPACTION_THRESHOLD = 4

  def initialize(ai_trainer)
    @ai_trainer = ai_trainer
    @user = ai_trainer.user
  end

  def call
    return unless should_compact?

    compacted = generate_compacted_prompt
    @ai_trainer.update!(system_prompt: compacted)
  end

  def should_compact?
    weekly_section_count >= COMPACTION_THRESHOLD
  end

  def weekly_section_count
    @ai_trainer.system_prompt.to_s.scan(/^## Week /m).size
  end

  private

  def generate_compacted_prompt
    client = GeminiClient.new(api_key: @user.ai_api_key, model: @user.ai_model)
    client.generate(
      build_prompt,
      log_context: {
        user: @user,
        action: "compact_trainer_prompt"
      }
    )
  end

  def build_prompt
    <<~PROMPT
      You are given a fitness trainer AI system prompt that has accumulated weekly observation sections over time.
      Your task is to produce a compacted version of this prompt.

      Rules:
      1. Keep the core trainer profile and communication guidelines sections exactly as they are.
      2. Consolidate all "## Week ..." sections into a single "## Accumulated Insights" section.
      3. In the Accumulated Insights section, organize information into:
         - **Current Strengths**: What the user is doing well (merged from all weeks, removing duplicates)
         - **Areas for Improvement**: What the user should work on (keep only the most recent/relevant)
         - **Key Recommendations**: Actionable advice (keep only current, non-superseded recommendations)
      4. Remove outdated observations that have been superseded by newer ones.
      5. Keep the consolidated insights concise — no more than 500 words.
      6. Do NOT add any commentary or explanation — return ONLY the compacted system prompt.

      Here is the current system prompt to compact:

      ---
      #{@ai_trainer.system_prompt}
      ---
    PROMPT
  end
end
