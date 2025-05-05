class WorkoutSetsController < ApplicationController
  def new
    @workout = Workout.find(params[:workout_id]) 
    @workout_set = WorkoutSet.new(workout: @workout)
  end

  def create
    @workout_set = WorkoutSet.new(workout_set_params.merge(started_at: Time.current))
    @workout_set.save!
  end

  def stop
    @workout_set = WorkoutSet.find(params[:id]) 
    @workout_set.update(ended_at: Time.current)
    @workout = @workout_set.workout
  end

  def destroy
    @workout_set = WorkoutSet.find(params[:id])
    @workout = @workout_set.workout
    @workout_set.destroy
    render :stop
  end

  private

  def workout_set_params
    params.require(:workout_set).permit(:exercise_id, :workout_id)
  end
end
