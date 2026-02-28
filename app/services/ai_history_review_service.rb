# frozen_string_literal: true

class AiHistoryReviewService
  include AiWorkoutPromptHelpers

  MAX_DATA_MONTHS = 6

  def initialize(ai_trainer)
    @ai_trainer = ai_trainer
    @user = ai_trainer.user
  end

  def call
    client = GeminiClient.new(api_key: @user.ai_api_key, model: @user.ai_model)
    client.generate(
      build_prompt,
      log_context: {
        user: @user,
        action: "full_review_initial"
      }
    )
  end

  private

  def build_prompt
    sections = [
      trainer_profile_section,
      workout_data_section,
      instruction_section
    ]
    sections.compact.join("\n\n")
  end

  def trainer_profile_section
    return nil if @ai_trainer.trainer_profile.blank?

    <<~PROMPT.strip
      ## Trainer Profile
      #{@ai_trainer.trainer_profile}
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

  def instruction_section
    <<~PROMPT.strip
      ## Task
      Based on the workout history above, provide a comprehensive training review. Include:
      1. Observed training patterns and preferences
      2. What went well — strengths and consistency
      3. Areas for improvement — gaps, imbalances, or missed opportunities
      4. Personalized recommendations going forward

      Keep your response under 500 words. Use markdown formatting.
      Respond in #{@user.locale == "ru" ? "Russian" : "English"}.
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
