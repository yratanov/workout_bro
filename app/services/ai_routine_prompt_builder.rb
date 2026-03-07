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
      superset_list_section,
      muscle_list_section,
      output_format_section
    ]
    sections.compact.join("\n\n")
  end

  private

  def task_instructions
    <<~PROMPT.strip
      You are a fitness trainer creating a workout routine. Based on the user's preferences and available exercises,
      create a structured workout routine. Prefer using exercises from the provided list, but you may suggest new exercises
      if needed — just provide a valid muscle group name. You may also suggest supersets (groups of exercises performed back-to-back).
      Prefer reusing existing supersets when they fit.
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
    lines << "Prefer using these existing exercises:"
    exercises.each do |exercise|
      muscle = exercise.muscle&.name || "unspecified"
      lines << "- #{exercise.name} (#{muscle})"
    end
    lines.join("\n")
  end

  def superset_list_section
    supersets =
      @user.supersets.includes(superset_exercises: :exercise).order(:name)
    return nil if supersets.empty?

    lines = []
    lines << "## Available Supersets"
    lines << "You can reuse these existing supersets:"
    supersets.each do |superset|
      exercise_names = superset.exercises.map(&:name).join(", ")
      lines << "- #{superset.name} (#{exercise_names})"
    end
    lines.join("\n")
  end

  def muscle_list_section
    muscle_names = Muscle.order(:name).pluck(:name)
    lines = []
    lines << "## Valid Muscle Groups"
    lines << "When suggesting new exercises, use one of these muscle group names:"
    lines << muscle_names.join(", ")
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
            "notes": "optional day-level notes or focus",
            "exercises": [
              { "name": "Exercise Name", "muscle": "chest", "comment": "optional tip or note", "sets": "3-4", "reps": "8-12", "min_rest": 60, "max_rest": 90 },
              { "superset": "Superset Name", "sets": "3", "reps": "10-12", "min_rest": 30, "max_rest": 60, "exercises": [
                { "name": "Exercise A", "muscle": "biceps", "comment": "optional tip" },
                { "name": "Exercise B", "muscle": "triceps" }
              ]}
            ]
          }
        ]
      }

      Rules:
      - The number of days MUST equal #{@frequency}
      - Each day should have 4-8 exercises
      - Each exercise item is either a solo exercise object with "name" and "muscle" keys, or a superset object with "superset" and "exercises" keys
      - For existing exercises, use the exact name from the list above
      - For new exercises, provide the exercise name and a valid muscle group from the list above
      - For supersets, reuse existing superset names when they fit, or create new ones
      - Give each day a descriptive name matching the split type
      - Order exercises logically (compound movements first, isolation last)
      - You may include a concise "comment" with tips or notes for each exercise (e.g., "focus on form", "use close grip")
      - Include "sets" and "reps" as strings (e.g., "3-4", "8-12") for recommended set/rep ranges
      - Include "min_rest" and "max_rest" as integers in seconds for recommended rest between sets
      - You may include "notes" on each day with a brief focus or goal for the day
      - Respond in #{@user.locale == "ru" ? "Russian" : "English"} for the routine name, day names, notes, and comments
    PROMPT
  end
end
