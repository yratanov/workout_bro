class SupersetExercisesController < ApplicationController
  before_action :set_superset

  def new
    @superset_exercise = @superset.superset_exercises.new
  end

  def create
    @superset_exercise =
      @superset.superset_exercises.new(superset_exercise_params)
    @superset_exercise.position = @superset.superset_exercises.count + 1

    if @superset_exercise.save
      render :create
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @superset_exercise = @superset.superset_exercises.find(params[:id])
    @superset_exercise.destroy

    reorder_positions
  end

  def move
    @superset_exercise = @superset.superset_exercises.find(params[:id])
    new_position = params[:position].to_i

    reorder_exercises(@superset_exercise, new_position)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "superset_exercises",
          partial: "superset_exercises/exercises",
          locals: { superset: @superset }
        )
      end
      format.html { head :ok }
    end
  end

  private

  def set_superset
    @superset = Current.user.supersets.find(params[:superset_id])
  end

  def superset_exercise_params
    params.require(:superset_exercise).permit(:exercise_id)
  end

  def reorder_positions
    @superset
      .superset_exercises
      .order(:position)
      .each_with_index { |se, index| se.update_column(:position, index + 1) }
  end

  def reorder_exercises(moved_exercise, new_position)
    exercises = @superset.superset_exercises.order(:position).to_a
    exercises.delete(moved_exercise)
    exercises.insert(new_position - 1, moved_exercise)

    exercises.each_with_index do |exercise, index|
      exercise.update_column(:position, index + 1)
    end
  end
end
