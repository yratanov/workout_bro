# frozen_string_literal: true

class WorkoutPillComponent < ViewComponent::Base
  def initialize(workout:)
    @workout = workout
  end

  def label
    if @workout.run?
      "Run"
    else
      @workout.workout_routine_day&.name || "Strength"
    end
  end

  def pill_classes
    base = "block px-2 py-1 text-xs rounded truncate hover:opacity-80 transition-opacity"

    if @workout.run?
      "#{base} bg-green-600 text-green-100"
    else
      "#{base} bg-blue-600 text-blue-100"
    end
  end

  def workout_path
    helpers.workout_path(@workout)
  end
end
