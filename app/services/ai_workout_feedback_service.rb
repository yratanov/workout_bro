# frozen_string_literal: true

class AiWorkoutFeedbackService
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

    lines << ""
    lines << "Exercises:"
    @workout
      .workout_sets
      .includes(:exercise, :workout_reps)
      .each do |ws|
        reps_info =
          ws.workout_reps.map { |r| "#{r.weight}kg x #{r.reps}" }.join(", ")
        next if reps_info.blank?

        set_line = "- #{ws.exercise.name}: #{reps_info}"
        set_line += " (#{format_duration(set_duration(ws))})" if set_duration(
          ws
        )
        lines << set_line

        previous_sets_info(ws).each { |prev_line| lines << prev_line }
      end

    prs = @workout.personal_records.includes(:exercise)
    if prs.any?
      lines << ""
      lines << "New Personal Records:"
      prs.each { |pr| lines << "- #{pr.exercise.name}: #{pr.pr_type.humanize}" }
    end

    lines.join("\n")
  end

  def run_details
    summary = WorkoutSummaryCalculator.new(workout: @workout).call
    lines = []
    lines << "Type: Run"
    lines << "Distance: #{(@workout.distance.to_f / 1000).round(2)}km"
    lines << "Duration: #{format_duration(summary.duration)}"
    lines << "Pace: #{format_pace(summary.pace)}" if summary.pace

    if summary.comparison&.pace_diff
      lines << "Pace change vs last time: #{summary.comparison.pace_diff.round(1)}s/km"
    end

    lines.join("\n")
  end

  def previous_sets_info(workout_set)
    previous_sets =
      @user
        .workout_sets
        .where(exercise: workout_set.exercise)
        .where.not(id: workout_set.id)
        .where.not(ended_at: nil)
        .includes(:workout_reps)
        .order(created_at: :desc)
        .limit(2)

    previous_sets.each_with_index.filter_map do |prev_set, i|
      reps =
        prev_set.workout_reps.map { |r| "#{r.weight}kg x #{r.reps}" }.join(", ")
      next if reps.blank?

      label = i.zero? ? "Previous" : "2 sessions ago"
      "  #{label}: #{reps}"
    end
  end

  def set_duration(workout_set)
    return nil unless workout_set.started_at && workout_set.ended_at

    elapsed = (workout_set.ended_at - workout_set.started_at).to_i
    elapsed - (workout_set.total_paused_seconds || 0)
  end

  def format_duration(seconds)
    return "N/A" unless seconds&.positive?

    minutes = seconds / 60
    remaining = seconds % 60
    "#{minutes}m #{remaining}s"
  end

  def format_pace(pace)
    return "N/A" unless pace&.positive?

    minutes = (pace / 60).to_i
    seconds = (pace % 60).to_i
    "#{minutes}:#{seconds.to_s.rjust(2, "0")} min/km"
  end
end
