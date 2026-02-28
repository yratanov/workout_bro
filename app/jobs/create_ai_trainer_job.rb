class CreateAiTrainerJob < ApplicationJob
  queue_as :default

  def perform(ai_trainer:)
    ai_trainer.in_progress!
    user = ai_trainer.user

    prompt = AiTrainerPromptBuilder.new(ai_trainer).call
    client = GeminiClient.new(api_key: user.ai_api_key, model: user.ai_model)
    summary =
      client.generate(prompt, log_context: { user:, action: "create_trainer" })
    system_prompt = AiTrainerSystemPromptCompiler.new(ai_trainer, summary).call

    ai_trainer.update!(
      summary:,
      system_prompt:,
      status: :completed,
      error_details: nil
    )
  rescue => e
    ai_trainer.update!(status: :failed, error_details: { message: e.message })
    raise
  end
end
