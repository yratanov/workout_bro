# frozen_string_literal: true

class AiConversationBuilder
  include AiWorkoutPromptHelpers

  TOKEN_THRESHOLD = 8000

  def initialize(ai_trainer)
    @ai_trainer = ai_trainer
  end

  def build
    { system_instruction: build_system_instruction, messages: activity_turns }
  end

  def estimated_token_count
    conversation = build
    tokens = estimate_tokens(conversation[:system_instruction])
    tokens += conversation[:messages].sum { |msg| estimate_tokens(msg[:text]) }
    tokens
  end

  def compaction_needed?
    estimated_token_count >= TOKEN_THRESHOLD
  end

  private

  def build_system_instruction
    sections = [
      static_instructions,
      trainer_profile_section,
      memories_section,
      full_review_section
    ]
    sections.compact.join("\n\n")
  end

  def static_instructions
    <<~PROMPT.strip
      You are a personal fitness trainer AI assistant. Your role is to help the user with their
      workout planning, form guidance, exercise selection, and motivation. Always prioritize safety
      and proper form. If the user describes pain or injury symptoms, recommend consulting a
      healthcare professional.
    PROMPT
  end

  def trainer_profile_section
    return nil if @ai_trainer.trainer_profile.blank?

    <<~PROMPT.strip
      ## Your Trainer Profile
      #{@ai_trainer.trainer_profile}
    PROMPT
  end

  def memories_section
    user = @ai_trainer.user
    memories = user.ai_memories.for_prompt.limit(25).to_a
    return nil if memories.empty?

    # Cap at 3 per category
    by_category = memories.group_by(&:category)
    capped = by_category.flat_map { |_, mems| mems.first(3) }

    lines = capped.map { |m| "- [#{m.category.capitalize}] #{m.content}" }

    <<~PROMPT.strip
      ## What I Know About This User
      #{lines.join("\n")}
    PROMPT
  end

  def full_review_section
    review = @ai_trainer.latest_full_review
    return nil unless review

    <<~PROMPT.strip
      ## Latest Training Review
      #{review.content}
    PROMPT
  end

  def activity_turns
    activities =
      @ai_trainer.activities_since_last_review.includes(
        workout: {
          workout_sets: :exercise
        }
      )

    activities.flat_map { |activity| turns_for_activity(activity) }
  end

  def turns_for_activity(activity)
    case activity.activity_type
    when "workout_review"
      workout_review_turns(activity)
    when "weekly_report"
      weekly_report_turns(activity)
    else
      []
    end
  end

  def workout_review_turns(activity)
    workout = activity.workout
    return [] unless workout

    user_text = condensed_workout_data(workout)
    [
      { role: "user", text: user_text },
      { role: "model", text: activity.content }
    ]
  end

  def weekly_report_turns(activity)
    week_label = activity.week_start&.strftime("%-d %b %Y") || "unknown"
    [
      { role: "user", text: "Weekly overview for week of #{week_label}" },
      { role: "model", text: activity.content }
    ]
  end

  def condensed_workout_data(workout)
    workout.strength? ? condensed_strength(workout) : condensed_run(workout)
  end

  def condensed_strength(workout)
    summary = WorkoutSummaryCalculator.new(workout: workout).call
    exercise_names =
      workout
        .workout_sets
        .includes(:exercise)
        .map { |ws| ws.exercise.name }
        .uniq

    lines = []
    lines << "Strength workout"
    lines << "Duration: #{format_duration(summary.duration)}"
    lines << "Exercises: #{exercise_names.join(", ")}"
    lines << "Notes: #{workout.notes}" if workout.notes.present?
    lines.join("\n")
  end

  def condensed_run(workout)
    summary = WorkoutSummaryCalculator.new(workout: workout).call
    lines = []
    lines << "Run workout"
    lines << "Distance: #{(workout.distance.to_f / 1000).round(2)}km"
    lines << "Duration: #{format_duration(summary.duration)}"
    lines << "Pace: #{format_pace(summary.pace)}" if summary.pace
    lines << "Notes: #{workout.notes}" if workout.notes.present?
    lines.join("\n")
  end

  def estimate_tokens(text)
    (text.length / 3.0).ceil
  end
end
