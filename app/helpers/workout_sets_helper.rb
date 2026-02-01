module WorkoutSetsHelper
  NextRoutineItem = Data.define(:is_superset, :superset_id, :exercise_id)

  def user_supersets
    Current
      .user
      .supersets
      .includes(:superset_exercises)
      .where.not(superset_exercises: { id: nil })
  end

  def next_routine_item_for_workout(workout)
    unless workout.workout_routine_day
      return (
        NextRoutineItem.new(
          is_superset: false,
          superset_id: nil,
          exercise_id: nil
        )
      )
    end

    routine_items =
      workout.workout_routine_day.workout_routine_day_exercises.order(:position)
    completed_exercise_ids = workout.exercise_ids
    completed_superset_ids =
      workout.workout_sets.where.not(superset_id: nil).pluck(:superset_id).uniq

    next_item =
      routine_items.find do |item|
        if item.superset?
          !completed_superset_ids.include?(item.superset_id)
        else
          !completed_exercise_ids.include?(item.exercise_id)
        end
      end

    if next_item&.superset?
      NextRoutineItem.new(
        is_superset: true,
        superset_id: next_item.superset_id,
        exercise_id: nil
      )
    elsif next_item
      NextRoutineItem.new(
        is_superset: false,
        superset_id: nil,
        exercise_id: next_item.exercise_id
      )
    else
      NextRoutineItem.new(
        is_superset: false,
        superset_id: nil,
        exercise_id: nil
      )
    end
  end

  def available_exercises_for_workout_set(workout_set)
    workout = workout_set.workout
    if workout.workout_routine_day
      (
        workout.workout_routine_day.exercises + Exercise.order(:name)
      ).uniq.without(workout.exercises)
    else
      Exercise.order(:name).where.not(id: workout.exercise_ids)
    end
  end

  def last_completed_workout_set(workout)
    workout.workout_sets.where.not(ended_at: nil).order(:ended_at).last
  end
end
