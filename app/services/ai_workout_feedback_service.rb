# frozen_string_literal: true

class AiWorkoutFeedbackService
  include AiWorkoutPromptHelpers

  def initialize(workout)
    @workout = workout
    @user = workout.user
    @ai_trainer = @user.ai_trainer
  end

  def call
    client = GeminiClient.new(api_key: @user.ai_api_key, model: @user.ai_model)
    client.generate(
      build_prompt,
      log_context: {
        user: @user,
        action: "workout_feedback"
      }
    )
  end

  private

  def build_prompt
    sections = [system_context, workout_data_section, instruction_section]
    sections.compact.join("\n\n")
  end

  def system_context
    return nil if @ai_trainer&.system_prompt.blank?

    <<~PROMPT.strip
      ## Your Role
      #{@ai_trainer.system_prompt}
    PROMPT
  end

  def workout_data_section
    <<~PROMPT.strip
      ## Workout Data
      #{workout_details}
    PROMPT
  end

  def instruction_section
    <<~PROMPT.strip
      ## Task
      Provide brief, specific feedback on this training session and the exercises performed.
      Focus on the actual numbers, progression compared to previous sessions, and exercise-specific observations.
      Do not give general training advice.
      Keep your response under 200 words. Use markdown formatting. Do not use headers.
      Respond in #{@user.locale == "ru" ? "Russian" : "English"}.
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
