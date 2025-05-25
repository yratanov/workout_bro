class WorkoutRoutineDayExercisesController < ApplicationController
  def destroy
    @workout_routine_day_exercise = WorkoutRoutineDayExercise.find(params[:id])
    @workout_routine_day = @workout_routine_day_exercise.workout_routine_day
    @workout_routine_day_exercise.destroy
  end

  def new
    @workout_routine_day = WorkoutRoutineDay.find(params[:workout_routine_day_id])
    @workout_routine_day_exercise = WorkoutRoutineDayExercise.new(workout_routine_day: @workout_routine_day)
  end

  def create
    @workout_routine_day_exercise = WorkoutRoutineDayExercise.new(workout_routine_day_exercise_params)
    @workout_routine_day = @workout_routine_day_exercise.workout_routine_day
    @workout_routine_day_exercise.position = @workout_routine_day.workout_routine_day_exercises.count + 1

    if @workout_routine_day_exercise.save
      render :create
    else
      render :new
    end
  end

  private

  def workout_routine_day_exercise_params
    params.require(:workout_routine_day_exercise).permit(
      :exercise_id,
      :workout_routine_day_id,
    )
  end
end
