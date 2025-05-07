class WorkoutRoutineDaysController < ApplicationController
  def edit
    @workout_routine_day = WorkoutRoutineDay.find(params[:id])
  end

  def update
  end
end
