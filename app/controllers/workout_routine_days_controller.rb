class WorkoutRoutineDaysController < ApplicationController
  def edit
    @workout_routine_day = WorkoutRoutineDay.find(params[:id])
  end

  def index
    @workout_routine = WorkoutRoutine.find(params[:workout_routine_id])
    @workout_routine_days = @workout_routine.workout_routine_days
  end

  def new
    @workout_routine = WorkoutRoutine.find(params[:workout_routine_id])
    @workout_routine_day =
      WorkoutRoutineDay.new(workout_routine: @workout_routine)
  end

  def create
    @workout_routine = WorkoutRoutine.find(params[:workout_routine_id])
    @workout_routine_day = WorkoutRoutineDay.new(workout_routine_day_params)
    @workout_routine_day.workout_routine = @workout_routine

    if @workout_routine_day.save
      redirect_to edit_workout_routine_workout_routine_day_path(
                    @workout_routine,
                    @workout_routine_day
                  ),
                  notice: I18n.t("controllers.workout_routine_days.created")
    else
      render :new
    end
  end

  def update
    @workout_routine_day = WorkoutRoutineDay.find(params[:id])
    if @workout_routine_day.update(workout_routine_day_params)
      redirect_to workout_routine_path(@workout_routine_day.workout_routine),
                  notice: I18n.t("controllers.workout_routine_days.updated")
    else
      render :edit
    end
  end

  private

  def workout_routine_day_params
    params.require(:workout_routine_day).permit(:name)
  end
end
