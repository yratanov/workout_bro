class GenerateAiWorkoutFeedbackJob < ApplicationJob
  include AiCompactionTrigger

  BROADCAST_THROTTLE_MS = 150

  queue_as :default

  def perform(workout:)
    return if workout.ai_trainer_activity&.completed?

    user = workout.user
    ai_trainer = user.ai_trainer
    return unless ai_trainer

    activity =
      workout.ai_trainer_activity ||
        AiTrainerActivity.new(
          user:,
          ai_trainer:,
          workout:,
          activity_type: :workout_review
        )

    if ai_trainer.configured?
      result = generate_with_streaming(workout, user)
    else
      result = AiWorkoutFeedbackService.new(workout).call
      broadcast_feedback(workout, result)
    end

    activity.update!(content: result, status: :completed)
    broadcast_feedback(workout, result, mark_viewed: true)

    trigger_compaction_if_needed(ai_trainer)
  rescue => e
    if activity&.persisted?
      activity&.update(status: :failed, error_message: e.message)
    end
    Rails.logger.error(
      "AI workout feedback failed for workout ##{workout.id}: #{e.message}"
    )
  end

  private

  def generate_with_streaming(workout, user)
    service = AiWorkoutFeedbackService.new(workout)
    client = AiClient.for(user)
    conversation = AiConversationBuilder.new(user.ai_trainer).build
    messages =
      conversation[:messages] + [{ role: "user", text: service.prompt }]

    last_broadcast = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    client.generate_chat_stream(
      messages,
      system_instruction: conversation[:system_instruction],
      generation_config: AiGenerator::GENERATION_CONFIG,
      log_context: {
        user:,
        action: "workout_feedback"
      }
    ) do |accumulated|
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      if (now - last_broadcast) * 1000 >= BROADCAST_THROTTLE_MS
        broadcast_feedback(workout, accumulated)
        last_broadcast = now
      end
    end
  end

  def broadcast_feedback(workout, text, mark_viewed: false)
    target = "ai_feedback_content_#{workout.id}"
    html = ApplicationController.helpers.render_markdown(text)
    extra_attrs =
      if mark_viewed
        url =
          Rails.application.routes.url_helpers.mark_ai_viewed_workout_path(
            workout
          )
        "data-controller=\"ai-feedback-viewed\" " \
          "data-ai-feedback-viewed-url-value=\"#{url}\" "
      else
        ""
      end
    Turbo::StreamsChannel.broadcast_replace_to(
      [workout, :ai_feedback],
      target:,
      html:
        "<div id=\"#{target}\" " \
          "#{extra_attrs}" \
          'class="text-slate-300 text-sm prose prose-invert prose-sm max-w-none">' \
          "#{html}</div>"
    )
  end
end
