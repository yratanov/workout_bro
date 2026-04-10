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

    @chart_data = build_chart_data(@workout_sets, @exercise)
    @workout_sets = @workout_sets.limit(50)
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

  def build_chart_data(workout_sets, exercise)
    grouped = workout_sets.group_by { |ws| ws.created_at.to_date }
    dates = grouped.keys.sort
    return {} if dates.empty?

    max_weight_data = []
    volume_data = []
    best_reps_data = []
    labels = dates.map { |d| I18n.l(d, format: :short) }

    dates.each do |date|
      all_reps = grouped[date].flat_map(&:workout_reps)

      if exercise.with_weights
        weights = all_reps.filter_map(&:weight)
        max_weight_data << (weights.max || 0)
        volume_data << all_reps.sum { |r| (r.weight || 0) * r.reps }
      end

      best_reps_data << (all_reps.map(&:reps).max || 0)
    end

    data = { labels: labels, best_reps: best_reps_data }
    if exercise.with_weights
      data[:max_weight] = max_weight_data
      data[:volume] = volume_data
    end
    data
  end

  # Only allow a list of trusted parameters through.
  def exercise_params
    params.expect(exercise: %i[name muscle_id with_weights with_band])
  end
end
