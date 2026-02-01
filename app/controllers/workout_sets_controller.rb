class WorkoutSetsController < ApplicationController
  def new
    @workout = Workout.find(params[:workout_id])
    @workout_set = WorkoutSet.new(workout: @workout)
  end

  def create
    @workout_set =
      WorkoutSet.new(workout_set_params.merge(started_at: Time.current))
    @workout_set.save!
  end

  def start_superset
    @workout = Workout.find(params[:workout_id])
    @superset = Current.user.supersets.find(params[:superset_id])

    superset_group = next_superset_group(@workout)

    @workout_sets =
      @superset
        .superset_exercises
        .order(:position)
        .map do |se|
          WorkoutSet.create!(
            workout: @workout,
            exercise: se.exercise,
            superset: @superset,
            superset_group: superset_group,
            started_at: Time.current
          )
        end

    @active_workout_set = @workout_sets.first
  end

  def stop
    @workout_set = WorkoutSet.find(params[:id])
    @workout = @workout_set.workout

    if @workout_set.in_superset?
      @workout_set.all_superset_sets.update_all(ended_at: Time.current)
    else
      @workout_set.update(ended_at: Time.current)
    end
  end

  def reopen
    @workout_set = WorkoutSet.find(params[:id])
    @workout_set.update(ended_at: nil)
    @workout = @workout_set.workout
  end

  def previous_history
    @workout_set = WorkoutSet.find(params[:id])
    @previous_set = @workout_set.previous_workout_set
  end

  def destroy
    @workout_set = WorkoutSet.find(params[:id])
    @workout = @workout_set.workout
    @workout_set.destroy
    render :stop
  end

  def notes_modal
    @workout_set = WorkoutSet.includes(:exercise).find(params[:id])
    render layout: false
  end

  def update_notes
    @workout_set = WorkoutSet.find(params[:id])
    @workout_set.update(notes: params[:workout_set][:notes])
  end

  private

  def workout_set_params
    params.require(:workout_set).permit(:exercise_id, :workout_id, :notes)
  end

  def next_superset_group(workout)
    (workout.workout_sets.maximum(:superset_group) || 0) + 1
  end
end
