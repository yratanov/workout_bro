# frozen_string_literal: true

class WorkoutPillComponent < ViewComponent::Base
  def initialize(workout:, compact: false)
    @workout = workout
    @compact = compact
  end

  def compact?
    @compact
  end

  def label
    if @workout.run?
      "Run"
    else
      @workout.workout_routine_day&.name || "Strength"
    end
  end

  def pill_classes
    if compact?
      base = "inline-block px-2 py-1 text-xs rounded hover:opacity-80 transition-opacity"
    else
      base = "block w-full px-2 py-1 text-xs rounded hover:opacity-80 transition-opacity"
    end

    if @workout.run?
      "#{base} bg-green-600 text-green-100"
    else
      "#{base} bg-blue-600 text-blue-100"
    end
  end

  def workout_path
    helpers.workout_path(@workout)
  end

  def modal_title
    date = @workout.created_at.strftime("%d %b %Y")
    if @workout.run?
      "Run · #{date}"
    else
      "#{@workout.workout_routine_day&.name || 'Strength'} · #{date}"
    end
  end
end
