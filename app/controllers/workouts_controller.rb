class WorkoutsController < ApplicationController
  before_action :set_workout, only: %i[ show edit update destroy stop]

  # GET /workouts or /workouts.json
  def index
    @workouts = Workout.all.order(started_at: :desc)
  end

  # GET /workouts/1 or /workouts/1.json
  def show
  end

  # GET /workouts/new
  def new
    @workout = Workout.new
  end

  # GET /workouts/1/edit
  def edit
  end

  # POST /workouts or /workouts.json
  def create
    if Workout.exists?(ended_at: nil)
      flash[:alert] = "You already have an active workout. Please stop it before starting a new one."
      @workouts = Workout.all
      render 'index'
      return
    end
    
    @workout = Workout.new(started_at: Time.current)

    respond_to do |format|
      if @workout.save
        format.html { redirect_to @workout, notice: "Workout was successfully created." }
        format.json { render :show, status: :created, location: @workout }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @workout.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # POST /workouts/1/stop
  def stop
    respond_to do |format|
      if @workout.update(ended_at: Time.current)
        format.html { redirect_to workouts_path, notice: "Workout was successfully ended." }
        format.json { render :show, status: :created, location: @workout }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @workout.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /workouts/1 or /workouts/1.json
  def update
    respond_to do |format|
      if @workout.update(workout_params)
        format.html { redirect_to @workout, notice: "Workout was successfully updated." }
        format.json { render :show, status: :ok, location: @workout }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @workout.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /workouts/1 or /workouts/1.json
  def destroy
    @workout.destroy!

    respond_to do |format|
      format.html { redirect_to workouts_path, status: :see_other, notice: "Workout was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_workout
      @workout = Workout.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def workout_params
      params.fetch(:workout, {})
    end
end
