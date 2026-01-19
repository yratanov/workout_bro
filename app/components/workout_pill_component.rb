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
    base = if compact?
             "inline-block px-2 py-1 text-xs rounded hover:opacity-80 transition-opacity"
    else
             "block w-full px-2 py-1 text-xs rounded hover:opacity-80 transition-opacity"
    end

    if @workout.run?
      "#{base} bg-green-600 text-green-100"
    else
      "#{base} bg-blue-600 text-blue-100"
    end
  end

  def modal_workout_path
    helpers.modal_workout_path(@workout)
  end
end
