class ExercisesController < ApplicationController
  before_action :set_exercise, only: %i[show edit update destroy]

  # GET /exercises or /exercises.json
  def index
    @exercises = Current.user.exercises.order(name: :asc)
  end

  # GET /exercises/1 or /exercises/1.json
  def show
    @workout_sets =
      Current
        .user
        .workout_sets
        .includes(:workout_reps, workout: :workout_routine_day)
        .where(exercise: @exercise)
        .where.not(ended_at: nil)
        .order(created_at: :desc)
        .limit(50)
  end

  # GET /exercises/new
  def new
    @exercise = Current.user.exercises.new
  end

  # GET /exercises/1/edit
  def edit
  end

  # POST /exercises or /exercises.json
  def create
    @exercise = Current.user.exercises.new(exercise_params)

    respond_to do |format|
      if @exercise.save
        format.html do
          redirect_to @exercise, notice: I18n.t("controllers.exercises.created")
        end
        format.json { render :show, status: :created, location: @exercise }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json do
          render json: @exercise.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH/PUT /exercises/1 or /exercises/1.json
  def update
    respond_to do |format|
      if @exercise.update(exercise_params)
        format.html do
          redirect_to @exercise, notice: I18n.t("controllers.exercises.updated")
        end
        format.json { render :show, status: :ok, location: @exercise }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json do
          render json: @exercise.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /exercises/1 or /exercises/1.json
  def destroy
    @exercise.destroy!

    respond_to do |format|
      format.html do
        redirect_to exercises_path,
                    status: :see_other,
                    notice: I18n.t("controllers.exercises.destroyed")
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_exercise
    @exercise = Current.user.exercises.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def exercise_params
    params.expect(exercise: %i[name muscle_id with_weights with_band])
  end
end
