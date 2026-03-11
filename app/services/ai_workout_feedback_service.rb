# frozen_string_literal: true

class AiWorkoutFeedbackService
  include AiWorkoutPromptHelpers

  def initialize(workout)
    @workout = workout
    @user = workout.user
  end

  def call
    AiGenerator.new(user: @user, action: "workout_feedback").call(
      prompt: prompt,
      chat_message: prompt
    )
  end

  def prompt
    sections = [
      workout_data_section,
      routine_prescription_section,
      instruction_section
    ].compact
    sections.join("\n\n")
  end

  private

  def workout_data_section
    <<~PROMPT.strip
      ## Workout Data
      #{workout_details}
    PROMPT
  end

  def instruction_section
    has_routine = @workout.workout_routine_day.present?

    <<~PROMPT.strip
      ## Task
      Analyze this workout and provide actionable insights. Focus on:
      - Progression patterns: are weights/reps trending up, stalling, or dropping?
      #{has_routine ? "- Plan adherence: compare what was performed vs what was prescribed in the routine." : ""}
      - Exercise-specific observations: volume distribution, rest patterns, weak points.
      - What to consider for next session.

      Do not restate the raw numbers. Provide analysis the user can't easily see themselves.
      Keep your feedback under 200 words. Use markdown formatting. Do not use headers.

      #{suggestions_instruction if has_routine}
      Respond in #{@user.locale == "ru" ? "Russian" : "English"}.
    PROMPT
  end

  def routine_prescription_section
    routine_day = @workout.workout_routine_day
    return nil unless routine_day

    exercises =
      routine_day
        .workout_routine_day_exercises
        .includes(:exercise, :superset)
        .order(:position)
    return nil if exercises.empty?

    lines = []
    lines << "## Routine Prescription (#{routine_day.workout_routine.name} - #{routine_day.name})"
    exercises.each do |rde|
      parts = ["- #{rde.display_name}"]
      parts << "sets: #{rde.sets}" if rde.sets.present?
      parts << "reps: #{rde.reps}" if rde.reps.present?
      if rde.min_rest.present? && rde.max_rest.present?
        parts << "rest: #{rde.min_rest}-#{rde.max_rest}s"
      end
      if rde.min_rest.present? ^ rde.max_rest.present?
        parts << "rest: #{rde.min_rest || rde.max_rest}s"
      end
      parts << "(#{rde.comment})" if rde.comment.present?
      lines << parts.join(" | ")
    end

    lines.join("\n")
  end

  def suggestions_instruction
    <<~PROMPT.strip
      After your feedback, if you have specific suggestions to adjust the routine prescription for any exercise,
      output them as a JSON array on a single line wrapped in <!--SUGGESTIONS:...--> tags.
      Each suggestion object: {"exercise": "Exercise Name", "field": "comment|sets|reps|min_rest|max_rest", "value": "new value", "reason": "short reason"}.
      Only suggest changes when the data clearly supports it. If no suggestions, omit the tag entirely.
      The "value" for comment should be a brief coaching cue (not a paragraph). For sets/reps use strings like "3-4" or "8-12". For rest use integers (seconds).
    PROMPT
  end

  def workout_details
    @workout.strength? ? strength_details : run_details
  end

  def strength_details
    summary = WorkoutSummaryCalculator.new(workout: @workout).call
    lines = []
    lines << "Type: Strength"
    lines << "Duration: #{format_duration(summary.duration)}"
    lines << "Total sets: #{summary.total_sets}"
    lines << "Total reps: #{summary.total_reps}"
    lines << "Notes: #{@workout.notes}" if @workout.notes.present?

    lines << ""
    lines << "Exercises:"
    lines.concat(format_workout_exercises(@workout.workout_sets, @user))

    prs = @workout.personal_records.includes(:exercise)
    if prs.any?
      lines << ""
      lines << "New Personal Records:"
      prs.each { |pr| lines << "- #{pr.exercise.name}: #{pr.pr_type.humanize}" }
    end

    lines.join("\n")
  end

  def run_details
    format_run_summary(@workout)
  end
end
