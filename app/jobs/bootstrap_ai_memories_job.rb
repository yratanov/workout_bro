# frozen_string_literal: true

class BootstrapAiMemoriesJob < ApplicationJob
  MAX_DATA_MONTHS = 6

  queue_as :default

  def perform(user:)
    return unless user.ai_configured?

    summary = build_workout_summary(user)
    return if summary.blank?

    AiMemoryExtractionService.new(user: user, activity_content: summary).call
  rescue => e
    Rails.logger.error(
      "AI memory bootstrap failed for user ##{user.id}: #{e.message}"
    )
  end

  private

  def build_workout_summary(user)
    exporter = WorkoutExporter.new(user: user)
    full_csv = exporter.call
    csv = filter_recent_data(full_csv)
    return nil if csv.blank?

    <<~SUMMARY
      ## Workout History Summary (last #{MAX_DATA_MONTHS} months)
      This is the user's raw workout data. Extract observations about their training patterns, preferences, and habits.

      ```csv
      #{csv}
      ```
    SUMMARY
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
