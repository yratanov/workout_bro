class AiRoutineSuggestionJob < ApplicationJob
  GENERATION_CONFIG = {
    temperature: 0.7,
    response_mime_type: "application/json"
  }.freeze

  queue_as :default

  def perform(workout_routine:, params:)
    workout_routine.ai_in_progress!
    user = workout_routine.user

    prompt = AiRoutinePromptBuilder.new(user, params).call
    client = AiClient.for(user)

    response =
      if user.ai_trainer&.configured?
        conversation = AiConversationBuilder.new(user.ai_trainer).build
        messages = conversation[:messages] + [{ role: "user", text: prompt }]
        client.generate_chat(
          messages,
          system_instruction: conversation[:system_instruction],
          generation_config: GENERATION_CONFIG,
          log_context: {
            user:,
            action: "routine_suggestion"
          }
        )
      else
        client.generate(
          prompt,
          generation_config: GENERATION_CONFIG,
          log_context: {
            user:,
            action: "routine_suggestion"
          }
        )
      end

    parsed = JSON.parse(response)
    build_routine(workout_routine, parsed, user)
    workout_routine.update!(ai_status: nil, ai_generation_error: nil)
  rescue => e
    workout_routine.update!(ai_status: :failed, ai_generation_error: e.message)
    raise
  end

  private

  def build_routine(workout_routine, data, user)
    exercises_by_name = user.exercises.index_by { |e| e.name.downcase }

    workout_routine.update!(name: data["name"]) if data["name"].present?

    data["days"]&.each do |day_data|
      day = workout_routine.workout_routine_days.create!(name: day_data["name"])

      day_data["exercises"]&.each_with_index do |exercise_name, position|
        exercise = exercises_by_name[exercise_name.strip.downcase]
        next unless exercise

        day.workout_routine_day_exercises.create!(exercise:, position:)
      end
    end
  end
end
