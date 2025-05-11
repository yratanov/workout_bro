class WorkoutRoutineDaysController < ApplicationController
  def edit
    @workout_routine_day = WorkoutRoutineDay.find(params[:id])
  end

  def index
    @workout_routine = WorkoutRoutine.find(params[:workout_routine_id])
    @workout_routine_days = @workout_routine.workout_routine_days
  end

  def update
  end
end
