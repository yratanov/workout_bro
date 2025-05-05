class WorkoutRepsController < ApplicationController
  def create
    @workout_rep = WorkoutRep.new(workout_rep_params)
    @workout_set = @workout_rep.workout_set
    @workout_rep.save!
  end
  
  private

  def workout_rep_params
    params.require(:workout_rep).permit(:weight, :reps, :workout_set_id)
  end
end
