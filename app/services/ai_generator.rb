# frozen_string_literal: true

class AiGenerator
  GENERATION_CONFIG = { temperature: 0.7 }.freeze

  def initialize(user:, action:)
    @user = user
    @action = action
    @ai_trainer = user.ai_trainer
  end

  def call(prompt:, chat_message:)
    client = AiClient.for(@user)
    log_context = { user: @user, action: @action }

    if @ai_trainer&.configured?
      conversation = AiConversationBuilder.new(@ai_trainer).build
      messages =
        conversation[:messages] + [{ role: "user", text: chat_message }]
      client.generate_chat(
        messages,
        system_instruction: conversation[:system_instruction],
        generation_config: GENERATION_CONFIG,
        log_context: log_context
      )
    else
      client.generate(
        prompt,
        generation_config: GENERATION_CONFIG,
        log_context: log_context
      )
    end
  end
end
