class WorkoutRepsController < ApplicationController
  def create
    @workout_rep = WorkoutRep.new(workout_rep_params)
    @workout_set = @workout_rep.workout_set
    @workout_rep.save!
  end

  def destroy
    @workout_rep = WorkoutRep.find(params[:id])
    @workout_set = @workout_rep.workout_set
    @workout_rep.destroy
  end
  
  private

  def workout_rep_params
    params.require(:workout_rep).permit(:weight, :reps, :workout_set_id, :band).tap do |whitelisted|
      whitelisted[:band] = nil if whitelisted[:band].blank?
    end
  end
end
