class WorkoutRoutinesController < ApplicationController
  def index
    @workout_routines = WorkoutRoutine.all.order(created_at: :desc)
  end

  def show
    @workout_routine = WorkoutRoutine.includes(workout_routine_days: :exercises).find(params[:id])
  end

  def destroy
    @workout_routine = WorkoutRoutine.find(params[:id])
    @workout_routine.destroy
    redirect_to workout_routines_path, notice: "Workout routine was successfully deleted."
  end
end
