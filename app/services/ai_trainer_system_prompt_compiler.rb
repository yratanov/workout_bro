# frozen_string_literal: true

class AiTrainerSystemPromptCompiler
  def initialize(ai_trainer, summary)
    @ai_trainer = ai_trainer
    @summary = summary
  end

  def call
    [static_instructions, trainer_summary, style_directives].compact.join(
      "\n\n"
    )
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

  def trainer_summary
    return nil if @summary.blank?

    <<~PROMPT.strip
      ## Your Trainer Profile
      #{@summary}
    PROMPT
  end

  def style_directives
    <<~PROMPT.strip
      ## Communication Guidelines
      - Approach: #{@ai_trainer.approach.humanize} — #{approach_description}
      - Style: #{@ai_trainer.communication_style.humanize} — #{style_description}
    PROMPT
  end

  def approach_description
    case @ai_trainer.approach
    when "supportive"
      "Be encouraging, patient, and positive. Celebrate small wins."
    when "tough_love"
      "Be direct, push the user to their limits, and hold them accountable."
    when "balanced"
      "Mix encouragement with honest feedback. Be supportive but don't shy away from pushing harder when needed."
    end
  end

  def style_description
    case @ai_trainer.communication_style
    when "concise"
      "Keep responses short and to the point. Use bullet points."
    when "detailed"
      "Provide thorough explanations with reasoning. Include context and alternatives."
    when "motivational"
      "Be energetic and inspiring. Use motivational language to keep the user engaged."
    end
  end
end
