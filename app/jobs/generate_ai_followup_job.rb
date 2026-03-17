# frozen_string_literal: true

class GenerateAiFollowupJob < ApplicationJob
  BROADCAST_THROTTLE_MS = 150

  queue_as :default

  def perform(activity:, question:)
    user = activity.user
    ai_trainer = user.ai_trainer
    return unless ai_trainer&.configured?

    activity.ai_trainer_messages.create!(role: :user, content: question)

    client = AiClient.for(user)
    conversation = AiConversationBuilder.new(ai_trainer).build
    messages =
      conversation[:messages] + followup_messages(activity) +
        [{ role: "user", text: question }]

    last_broadcast = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    result =
      client.generate_chat_stream(
        messages,
        system_instruction: conversation[:system_instruction],
        generation_config: AiGenerator::GENERATION_CONFIG,
        log_context: {
          user:,
          action: "workout_followup"
        }
      ) do |accumulated|
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        if (now - last_broadcast) * 1000 >= BROADCAST_THROTTLE_MS
          broadcast_response(activity, accumulated)
          last_broadcast = now
        end
      end

    message =
      activity.ai_trainer_messages.create!(role: :assistant, content: result)
    broadcast_response(activity, result, final: true, message:)
  rescue => e
    broadcast_error(activity)
    Rails.logger.error(
      "AI followup failed for activity ##{activity.id}: #{e.message}"
    )
  end

  private

  def followup_messages(activity)
    activity
      .ai_trainer_messages
      .order(:created_at)
      .map { |msg| { role: msg.user? ? "user" : "model", text: msg.content } }
  end

  def broadcast_response(activity, text, final: false, message: nil)
    target = "ai_chat_response_#{activity.id}"
    html = ApplicationController.helpers.render_markdown(text)
    extra = final && message ? " data-message-id=\"#{message.id}\"" : ""
    Turbo::StreamsChannel.broadcast_replace_to(
      [activity, :ai_chat],
      target:,
      html:
        "<div id=\"#{target}\"#{extra} " \
          'class="text-slate-300 text-sm prose prose-invert prose-sm max-w-none">' \
          "#{html}</div>"
    )
  end

  def broadcast_error(activity)
    return unless activity

    target = "ai_chat_response_#{activity.id}"
    Turbo::StreamsChannel.broadcast_replace_to(
      [activity, :ai_chat],
      target:,
      html:
        "<div id=\"#{target}\" class=\"text-red-400 text-sm\">" \
          "Something went wrong. Please try again.</div>"
    )
  end
end
