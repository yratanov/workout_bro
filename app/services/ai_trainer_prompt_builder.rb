# frozen_string_literal: true

class AiTrainerPromptBuilder
  def initialize(ai_trainer)
    @ai_trainer = ai_trainer
  end

  def call
    sections = [role_instructions, personality_section, goals_section]
    sections.compact.join("\n\n")
  end

  private

  def role_instructions
    <<~PROMPT.strip
      You are creating a personalized AI fitness trainer persona. Based on the information below,
      generate a detailed trainer profile summary in markdown format. Include:

      1. A trainer personality description matching the requested style
      2. How the trainer should communicate and motivate
      3. Key focus areas based on the user's goals

      Keep the summary concise but actionable (under 500 words).
    PROMPT
  end

  def personality_section
    <<~PROMPT.strip
      ## Trainer Personality
      - Approach: #{@ai_trainer.approach.humanize}
      - Communication style: #{@ai_trainer.communication_style.humanize}
      #{"- Custom instructions: #{@ai_trainer.custom_instructions}" if @ai_trainer.custom_instructions.present?}
    PROMPT
  end

  def goals_section
    active_goals =
      @ai_trainer.goals.map { |g| g.to_s.sub("goal_", "").humanize }
    return nil if active_goals.empty?

    <<~PROMPT.strip
      ## User Goals
      #{active_goals.map { |g| "- #{g}" }.join("\n")}
    PROMPT
  end
end
