# frozen_string_literal: true

class CalendarDayComponent < ViewComponent::Base
  def initialize(date:, current_month:, workouts:)
    @date = date
    @current_month = current_month
    @workouts = workouts
  end

  def in_current_month?
    @date.month == @current_month.month && @date.year == @current_month.year
  end

  def today?
    @date == Date.current
  end

  def day_classes
    base = "min-h-24 p-1 rounded bg-slate-700 border"

    if today?
      "#{base} border-sky-500"
    elsif in_current_month?
      "#{base} border-slate-600"
    else
      "#{base} border-slate-600 opacity-50"
    end
  end

  def day_number_classes
    base = "text-sm font-medium mb-1"
    in_current_month? ? "#{base} text-slate-200" : "#{base} text-slate-500"
  end
end
