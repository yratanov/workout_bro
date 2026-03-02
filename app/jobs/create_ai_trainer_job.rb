class CreateAiTrainerJob < ApplicationJob
  GENERATION_CONFIG = { temperature: 0.8 }.freeze

  queue_as :default

  def perform(ai_trainer:)
    ai_trainer.in_progress!
    user = ai_trainer.user

    prompt = AiTrainerPromptBuilder.new(ai_trainer).call
    client = AiClient.for(user)
    trainer_profile =
      client.generate(
        prompt,
        generation_config: GENERATION_CONFIG,
        log_context: {
          user:,
          action: "create_trainer"
        }
      )

    ai_trainer.update!(trainer_profile:, status: :completed, error_details: nil)

    if ai_trainer.train_on_existing_data
      GenerateFullReviewJob.perform_later(ai_trainer:)
    end
  rescue => e
    ai_trainer.update!(status: :failed, error_details: { message: e.message })
    raise
  end
end
