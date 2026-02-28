# frozen_string_literal: true

class AiTrainerPromptBuilder
  MAX_DATA_MONTHS = 6

  def initialize(ai_trainer)
    @ai_trainer = ai_trainer
    @user = ai_trainer.user
  end

  def call
    sections = [role_instructions, personality_section, goals_section]
    sections << workout_data_section if @ai_trainer.train_on_existing_data
    sections.compact.join("\n\n")
  end

  private

  def role_instructions
    <<~PROMPT.strip
      You are creating a personalized AI fitness trainer persona. Based on the information below,
      generate a detailed trainer profile summary in markdown format. Include:

      1. A trainer personality description matching the requested style
      2. How the trainer should communicate and motivate
      3. Key focus areas based on the user's goals
      4. If workout data is provided, analyze it and include:
         - Observed training patterns and preferences
         - Strengths and areas for improvement
         - Personalized recommendations based on their history

      Keep the summary concise but actionable (under 500 words).
    PROMPT
  end

  def personality_section
    <<~PROMPT.strip
      ## Trainer Personality
      - Approach: #{@ai_trainer.approach.humanize}
      - Communication style: #{@ai_trainer.communication_style.humanize}
      #{"- Custom instructions: #{@ai_trainer.custom_instructions}" if @ai_trainer.custom_instructions.present?}
    PROMPT
  end

  def goals_section
    active_goals =
      @ai_trainer.goals.map { |g| g.to_s.sub("goal_", "").humanize }
    return nil if active_goals.empty?

    <<~PROMPT.strip
      ## User Goals
      #{active_goals.map { |g| "- #{g}" }.join("\n")}
    PROMPT
  end

  def workout_data_section
    csv = workout_csv
    return nil if csv.blank?

    <<~PROMPT.strip
      ## Workout History (last #{MAX_DATA_MONTHS} months)
      Analyze this CSV data to understand the user's training patterns:

      ```csv
      #{csv}
      ```
    PROMPT
  end

  def workout_csv
    exporter = WorkoutExporter.new(user: @user)
    full_csv = exporter.call
    filter_recent_data(full_csv)
  end

  def filter_recent_data(csv)
    lines = csv.lines
    return "" if lines.size <= 1

    cutoff = MAX_DATA_MONTHS.months.ago.to_date
    header = lines.first
    recent_lines =
      lines[1..].select do |line|
        date_str = line.split(",").first
        begin
          Date.parse(date_str) >= cutoff
        rescue Date::Error
          false
        end
      end

    return "" if recent_lines.empty?

    header + recent_lines.join
  end
end
