# frozen_string_literal: true

class CalendarComponent < ViewComponent::Base
  def initialize(current_date:, calendar_start:, calendar_end:, workouts_by_date:, prev_month:, next_month:)
    @current_date = current_date
    @calendar_start = calendar_start
    @calendar_end = calendar_end
    @workouts_by_date = workouts_by_date
    @prev_month = prev_month
    @next_month = next_month
  end

  def weeks
    (@calendar_start..@calendar_end).to_a.each_slice(7)
  end

  def day_names
    %w[Mon Tue Wed Thu Fri Sat Sun]
  end

  def month_title
    @current_date.strftime("%B %Y")
  end

  def prev_month_path
    helpers.workouts_path(month: @prev_month.strftime("%Y-%m-01"))
  end

  def next_month_path
    helpers.workouts_path(month: @next_month.strftime("%Y-%m-01"))
  end
end
