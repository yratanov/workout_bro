# frozen_string_literal: true

module AiClients
  class Fake < Base
    SIMULATED_DELAY = 0.5

    def initialize(**_options)
    end

    def generate(prompt, generation_config: nil, log_context: nil)
      sleep(SIMULATED_DELAY)
      response = fake_response(prompt, log_context)
      log_request(response:, log_context:, prompt:)
      response
    end

    def generate_chat(
      messages,
      system_instruction: nil,
      generation_config: nil,
      log_context: nil
    )
      sleep(SIMULATED_DELAY)
      prompt = messages.last&.dig(:text) || ""
      response = fake_response(prompt, log_context)
      log_request(response:, log_context:, prompt: prompt)
      response
    end

    def generate_chat_stream(
      messages,
      system_instruction: nil,
      generation_config: nil,
      log_context: nil,
      &block
    )
      prompt = messages.last&.dig(:text) || ""
      response = fake_response(prompt, log_context)

      # Simulate streaming by yielding accumulated chunks
      words = response.split(" ")
      accumulated = +""
      words.each_with_index do |word, i|
        accumulated << " " unless i.zero?
        accumulated << word
        sleep(0.02)
        yield accumulated if block_given?
      end

      log_request(response:, log_context:, prompt: prompt)
      response
    end

    private

    def fake_response(prompt, log_context)
      action = log_context&.dig(:action)

      case action
      when "memory_extraction"
        memory_extraction_response
      when "create_trainer"
        trainer_profile_response
      when "workout_feedback"
        workout_feedback_response
      when "weekly_report"
        weekly_report_response
      when "full_review_initial", "full_review_compaction"
        history_review_response
      when "routine_suggestion"
        routine_suggestion_response
      else
        generic_response
      end
    end

    def memory_extraction_response
      "NONE"
    end

    def trainer_profile_response
      <<~TEXT.strip
        **Coach Dev** — Your AI Training Partner

        I'm a balanced fitness coach focused on helping you build strength and consistency.
        I'll track your progress, suggest improvements, and keep you motivated.
        Let's train smart and make every session count!
      TEXT
    end

    def workout_feedback_response
      <<~TEXT.strip
        Solid session today! Your volume and intensity looked good overall.

        **Highlights:**
        - Good consistency with your working weights
        - Rest times were well-managed between sets
        - Form appeared controlled throughout

        **Suggestions:**
        - Consider adding one more warm-up set on your compound lifts
        - Try to increase weight by 2.5kg next session on your top sets

        Keep up the great work — consistency is what builds results.
      TEXT
    end

    def weekly_report_response
      <<~TEXT.strip
        ## Weekly Overview

        Good training week with solid consistency.

        **Volume & Frequency:** You maintained a good training rhythm this week.
        Your total volume is trending in the right direction.

        **Progression:** Weights are holding steady — look for opportunities to
        push slightly heavier on your main lifts next week.

        **Recovery:** Make sure you're getting adequate sleep and nutrition to
        support your training load.

        **Next Week Focus:** Aim to add a small increment to at least one
        compound lift while maintaining your current volume.
      TEXT
    end

    def history_review_response
      <<~TEXT.strip
        ## Training Review

        **Patterns:** You train consistently with a good mix of exercises.
        Your workout frequency and exercise selection show a well-rounded approach.

        **Strengths:** Good adherence to your routine with steady progression
        on key lifts. You're building a solid foundation.

        **Areas for Improvement:** Consider adding more variety in rep ranges —
        mixing heavy sets (3-5 reps) with moderate sets (8-12 reps) can help
        break plateaus.

        **Recommendations:**
        - Track rest periods more consistently
        - Add a deload week every 4-6 weeks
        - Consider periodizing your training for long-term progress
      TEXT
    end

    def routine_suggestion_response
      {
        name: "Dev Test Routine",
        days: [
          {
            name: "Day A — Upper Body",
            exercises: [
              { name: "Bench Press", muscle: "chest", comment: "4x8-10" },
              { name: "Barbell Row", muscle: "back", comment: "4x8-10" },
              {
                name: "Overhead Press",
                muscle: "shoulders",
                comment: "3x10-12"
              }
            ]
          },
          {
            name: "Day B — Lower Body",
            exercises: [
              { name: "Squat", muscle: "quadriceps", comment: "4x6-8" },
              {
                name: "Romanian Deadlift",
                muscle: "hamstrings",
                comment: "3x10-12"
              },
              { name: "Leg Press", muscle: "quadriceps", comment: "3x12-15" }
            ]
          }
        ]
      }.to_json
    end

    def generic_response
      "This is a fake AI response for development. Configure a real AI provider to get actual responses."
    end

    def log_request(response:, log_context:, prompt:)
      return unless log_context&.dig(:user) && log_context&.dig(:action)

      AiLog.create!(
        user: log_context[:user],
        action: log_context[:action],
        model: "fake",
        prompt: prompt.to_s.truncate(10_000),
        response: response,
        duration_ms: (SIMULATED_DELAY * 1000).to_i,
        input_tokens: 0,
        output_tokens: 0,
        total_tokens: 0
      )
    rescue => e
      Rails.logger.error("Failed to log fake AI request: #{e.message}")
    end
  end
end
