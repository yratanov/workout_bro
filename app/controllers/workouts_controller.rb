class WorkoutsController < ApplicationController
  before_action :set_workout, only: %i[ edit update destroy stop pause resume]

  # GET /workouts or /workouts.json
  def index
    @current_date = params[:month].present? ? Date.parse(params[:month]) : Date.current

    @calendar_start = @current_date.beginning_of_month.beginning_of_week(:monday)
    @calendar_end = @current_date.end_of_month.end_of_week(:monday)

    @active_workout = current_user.workouts.find_by(ended_at: nil)

    @workouts = current_user.workouts
      .includes(:workout_routine_day)
      .where(started_at: @calendar_start.beginning_of_day..@calendar_end.end_of_day)
      .order(:started_at)

    @workouts_by_date = @workouts.group_by { |w| w.started_at.to_date }

    @prev_month = @current_date - 1.month
    @next_month = @current_date + 1.month
  end

  # GET /workouts/1 or /workouts/1.json
  def show
    @workout = current_user.workouts.includes(workout_sets: :exercise).find(params[:id])
  end

  # GET /workouts/new
  def new
    @default_workout_routine = WorkoutRoutine.last
    @workout = Workout.new(
      workout_routine_day: @default_workout_routine.workout_routine_days.first,
      workout_type: :strength,
      started_at: Time.current,
    )
  end

  # GET /workouts/1/edit
  def edit
  end

  # POST /workouts or /workouts.json
  def create
    if Workout.exists?(user: current_user, ended_at: nil)
      flash[:alert] = "You already have an active workout. Please stop it before starting a new one."
      @workouts = Workout.all
      render 'index'
      return
    end
    
    @workout = Workout.new(workout_params.merge(user: current_user))

    if @workout.run?
      @workout.workout_routine_day = nil
      if params[:workout][:time_in_seconds]
        (hours, minutes, seconds) = params[:workout][:time_in_seconds].split(":")
        if seconds.nil?
          minutes, seconds = hours, minutes
          hours = 0 
        end
        @workout.time_in_seconds = hours.to_i * 60 * 60 +  minutes.to_i * 60 + seconds.to_i
        @workout.ended_at = @workout.started_at ? @workout.started_at + @workout.time_in_seconds.seconds : nil
      end
    else
      @workout.started_at = Time.current
      @workout.distance = nil
      @workout.time_in_seconds = nil
    end

    respond_to do |format|
      if @workout.save
        format.html do
          if @workout.run?
            redirect_to workouts_path, notice: "Workout was successfully created."
          else
            redirect_to @workout, notice: "Workout was successfully created."
          end
        end
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
      @workout.workout_sets.where(ended_at: nil).each do |workout_set|
        workout_set.update(ended_at: Time.current)
      end
      if @workout.update(ended_at: Time.current)
        format.html { redirect_to workouts_path, notice: "Workout was successfully ended." }
        format.json { render :show, status: :created, location: @workout }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @workout.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /workouts/1/pause
  def pause
    if @workout.running? && !@workout.paused?
      now = Time.current
      @workout.update(paused_at: now)
      @workout.workout_sets.where(ended_at: nil, paused_at: nil).update_all(paused_at: now)
    end
    redirect_to @workout
  end

  # POST /workouts/1/resume
  def resume
    if @workout.paused?
      now = Time.current
      pause_duration = (now - @workout.paused_at).to_i
      @workout.update(
        paused_at: nil,
        total_paused_seconds: @workout.total_paused_seconds + pause_duration
      )
      @workout.workout_sets.where(ended_at: nil).where.not(paused_at: nil).find_each do |set|
        set_pause_duration = (now - set.paused_at).to_i
        set.update(
          paused_at: nil,
          total_paused_seconds: set.total_paused_seconds + set_pause_duration
        )
      end
    end
    redirect_to @workout
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
      @workout = current_user.workouts.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def workout_params
      params.require(:workout).permit(:workout_routine_day_id, :workout_type, :distance, :started_at)
    end
end
