class AiRoutinePromptBuilder
  def initialize(user, params)
    @user = user
    @frequency = params[:frequency].to_i
    @split_type = params[:split_type]
    @experience_level = params[:experience_level]
    @focus_areas = params[:focus_areas]&.reject(&:blank?) || []
    @additional_context = params[:additional_context]
  end

  def call
    sections = [
      task_instructions,
      user_preferences_section,
      exercise_list_section,
      output_format_section
    ]
    sections.compact.join("\n\n")
  end

  private

  def task_instructions
    <<~PROMPT.strip
      You are a fitness trainer creating a workout routine. Based on the user's preferences and available exercises,
      create a structured workout routine. You MUST only use exercise names exactly as they appear in the provided list.
      Do not invent or modify exercise names.
    PROMPT
  end

  def user_preferences_section
    lines = []
    lines << "## User Preferences"
    lines << "- Training frequency: #{@frequency} days per week"
    lines << "- Split type: #{@split_type}"
    lines << "- Experience level: #{@experience_level}"
    lines << "- Focus areas: #{@focus_areas.join(", ")}" if @focus_areas.any?
    if @additional_context.present?
      lines << "- Additional context: #{@additional_context}"
    end
    lines.join("\n")
  end

  def exercise_list_section
    exercises = @user.exercises.includes(:muscle).order(:name)
    lines = []
    lines << "## Available Exercises"
    lines << "Use ONLY these exact exercise names:"
    exercises.each do |exercise|
      muscle = exercise.muscle&.name || "unspecified"
      lines << "- #{exercise.name} (#{muscle})"
    end
    lines.join("\n")
  end

  def output_format_section
    <<~PROMPT.strip
      ## Output Format
      Respond with valid JSON only, no markdown formatting or code blocks. Use this exact structure:
      {
        "name": "Routine name",
        "days": [
          {
            "name": "Day name (e.g., Push Day, Upper Body A)",
            "exercises": ["Exact Exercise Name 1", "Exact Exercise Name 2"]
          }
        ]
      }

      Rules:
      - The number of days MUST equal #{@frequency}
      - Each day should have 4-8 exercises
      - Use exercise names EXACTLY as listed above
      - Give each day a descriptive name matching the split type
      - Order exercises logically (compound movements first, isolation last)
      - Respond in #{@user.locale == "ru" ? "Russian" : "English"} for the routine name and day names
    PROMPT
  end
end
