class WorkoutRoutinesController < ApplicationController
  def index
    @workout_routines = current_user.workout_routines.order(created_at: :desc)
  end

  def show
    @workout_routine = current_user.workout_routines.includes(workout_routine_days: :exercises).find(params[:id])
  end

  def new
    @workout_routine = current_user.workout_routines.build
  end

  def create
    @workout_routine = current_user.workout_routines.build(workout_routine_params)

    if @workout_routine.save
      redirect_to @workout_routine, notice: I18n.t("controllers.workout_routines.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @workout_routine = current_user.workout_routines.find(params[:id])
    @workout_routine.destroy
    redirect_to workout_routines_path, notice: I18n.t("controllers.workout_routines.destroyed")
  end

  private

  def workout_routine_params
    params.require(:workout_routine).permit(:name)
  end
end
