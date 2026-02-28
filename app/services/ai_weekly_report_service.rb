# frozen_string_literal: true

class AiWeeklyReportService
  include AiWorkoutPromptHelpers

  def initialize(user, week_start)
    @user = user
    @week_start = week_start
    @ai_trainer = @user.ai_trainer
  end

  def call
    client = GeminiClient.new(api_key: @user.ai_api_key, model: @user.ai_model)
    client.generate(
      build_prompt,
      log_context: {
        user: @user,
        action: "weekly_report"
      }
    )
  end

  private

  def build_prompt
    sections = [system_context, week_data_section, instruction_section]
    sections.compact.join("\n\n")
  end

  def system_context
    return nil unless @ai_trainer

    <<~PROMPT.strip
      ## Your Role
      #{AiPromptContextBuilder.new(@ai_trainer).call}
    PROMPT
  end

  def week_data_section
    <<~PROMPT.strip
      ## Training Week: #{@week_start.strftime("%-d %b %Y")} – #{week_end.strftime("%-d %b %Y")}
      #{workouts_data}
    PROMPT
  end

  def instruction_section
    <<~PROMPT.strip
      ## Task
      Provide a weekly overview analyzing this training week.
      Assess the overall direction and progression.
      Include personalized recommendations based on the past week.
      Keep your response under 400 words. Use markdown formatting.
      Respond in #{@user.locale == "ru" ? "Russian" : "English"}.
    PROMPT
  end

  def workouts_data
    workouts =
      @user
        .workouts
        .where(ended_at: @week_start.beginning_of_day..week_end.end_of_day)
        .order(:started_at)
        .includes(
          workout_sets: %i[exercise workout_reps],
          personal_records: :exercise
        )

    return "No completed workouts this week." if workouts.empty?

    workouts.map { |w| format_workout(w) }.join("\n\n")
  end

  def format_workout(workout)
    lines = []
    lines << "### #{workout.date&.strftime("%A, %-d %b")} — #{workout.strength? ? "Strength" : "Run"}"

    if workout.strength?
      summary = WorkoutSummaryCalculator.new(workout: workout).call
      lines << "Duration: #{format_duration(summary.duration)}"
      lines << "Notes: #{workout.notes}" if workout.notes.present?
      lines << ""
      lines << "Exercises:"
      lines.concat(format_workout_exercises(workout.workout_sets, @user))

      prs = workout.personal_records
      if prs.any?
        lines << ""
        lines << "New Personal Records:"
        prs.each do |pr|
          lines << "- #{pr.exercise.name}: #{pr.pr_type.humanize}"
        end
      end
    else
      lines << format_run_summary(workout)
    end

    lines.join("\n")
  end

  def week_end
    @week_start + 6.days
  end
end
