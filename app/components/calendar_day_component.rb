# frozen_string_literal: true

class CalendarDayComponent < ViewComponent::Base
  def initialize(date:, current_month:, workouts:, mobile: false)
    @date = date
    @current_month = current_month
    @workouts = workouts
    @mobile = mobile
  end

  def mobile?
    @mobile
  end

  def in_current_month?
    @date.month == @current_month.month && @date.year == @current_month.year
  end

  def today?
    @date == Date.current
  end

  def day_classes
    if mobile?
      base = "flex items-center gap-3 p-2 rounded bg-slate-700 border"
      if today?
        "#{base} border-sky-500"
      else
        "#{base} border-slate-600"
      end
    else
      base = "min-h-24 p-1 rounded bg-slate-700 border"
      if today?
        "#{base} border-sky-500"
      elsif in_current_month?
        "#{base} border-slate-600"
      else
        "#{base} border-slate-600 opacity-50"
      end
    end
  end

  def day_number_classes
    if mobile?
      "text-sm font-medium text-slate-200 w-16 flex-shrink-0"
    else
      base = "text-sm font-medium mb-1"
      in_current_month? ? "#{base} text-slate-200" : "#{base} text-slate-500"
    end
  end

  def formatted_date
    @date.strftime("%a, %b %d")
  end
end
