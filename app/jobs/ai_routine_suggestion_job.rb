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
    broadcast_reload(workout_routine)
  rescue => e
    workout_routine.update!(ai_status: :failed, ai_generation_error: e.message)
    broadcast_reload(workout_routine)
    raise
  end

  private

  def broadcast_reload(workout_routine)
    Turbo::StreamsChannel.broadcast_replace_to(
      [workout_routine, :ai_generation],
      target: "ai_generation_status",
      html:
        '<div id="ai_generation_status" data-controller="page-reload"></div>'
    )
  end

  def build_routine(workout_routine, data, user)
    @exercises_by_name = user.exercises.index_by { |e| e.name.downcase }
    @supersets_by_name = user.supersets.index_by { |s| s.name.downcase }
    @muscles_by_name = Muscle.all.index_by { |m| m.name.downcase }
    @user = user

    workout_routine.update!(name: data["name"]) if data["name"].present?

    data["days"]&.each do |day_data|
      day = workout_routine.workout_routine_days.create!(name: day_data["name"])

      day_data["exercises"]&.each_with_index do |item, position|
        if item.is_a?(Hash) && item["superset"].present?
          add_superset_to_day(day, item, position)
        elsif item.is_a?(Hash) && item["name"].present?
          add_exercise_to_day(day, item, position)
        end
      end
    end
  end

  def add_exercise_to_day(day, item, position)
    exercise = resolve_exercise(item["name"], item["muscle"])
    return unless exercise

    day.workout_routine_day_exercises.create!(
      exercise:,
      position:,
      comment: item["comment"]
    )
  end

  def add_superset_to_day(day, item, position)
    superset = resolve_superset(item["superset"], item["exercises"] || [])
    return unless superset

    day.workout_routine_day_exercises.create!(
      superset:,
      position:,
      comment: item["comment"]
    )
  end

  def resolve_exercise(name, muscle_name)
    existing = @exercises_by_name[name.strip.downcase]
    return existing if existing

    muscle = @muscles_by_name[muscle_name&.strip&.downcase]
    return nil unless muscle

    exercise =
      @user.exercises.create!(name: name.strip, muscle:, with_weights: true)
    @exercises_by_name[exercise.name.downcase] = exercise
    exercise
  end

  def resolve_superset(name, exercise_items)
    existing = @supersets_by_name[name.strip.downcase]
    return existing if existing

    exercises =
      exercise_items.filter_map do |item|
        resolve_exercise(item["name"], item["muscle"])
      end
    return nil if exercises.empty?

    superset = @user.supersets.create!(name: name.strip)
    exercises.each_with_index do |exercise, idx|
      superset.superset_exercises.create!(exercise:, position: idx + 1)
    end
    @supersets_by_name[superset.name.downcase] = superset
    superset
  end
end
