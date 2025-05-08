class WorkoutRoutinesController < ApplicationController
  def index
    @workout_routines = current_user.workout_routines.order(created_at: :desc)
  end

  def show
    @workout_routine = current_user.workout_routines.includes(workout_routine_days: :exercises).find(params[:id])
  end

  def destroy
    @workout_routine = current_user.workout_routines.find(params[:id])
    @workout_routine.destroy
    redirect_to workout_routines_path, notice: "Workout routine was successfully deleted."
  end
end
