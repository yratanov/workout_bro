# frozen_string_literal: true

class GenerateAllWeeklyReportsJob < ApplicationJob
  queue_as :default

  def perform
    week_start = Date.current.beginning_of_week(:monday) - 7.days

    User.find_each do |user|
      next unless user.ai_configured?
      next unless user.ai_trainer&.completed?
      unless user
               .workouts
               .where(
                 ended_at:
                   week_start.beginning_of_day..(week_start + 6.days).end_of_day
               )
               .exists?
        next
      end

      GenerateWeeklyReportJob.perform_later(user: user, week_start: week_start)
    end
  end
end
