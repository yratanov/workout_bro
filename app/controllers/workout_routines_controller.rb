class WorkoutRoutinesController < ApplicationController
  def index
    @workout_routines = current_user.workout_routines.order(created_at: :desc)
  end

  def show
    @workout_routine =
      current_user
        .workout_routines
        .includes(workout_routine_days: :exercises)
        .find(params[:id])
  end

  def new
    @workout_routine = current_user.workout_routines.build
  end

  def create
    @workout_routine =
      current_user.workout_routines.build(workout_routine_params)

    if @workout_routine.save
      redirect_to @workout_routine,
                  notice: I18n.t("controllers.workout_routines.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @workout_routine = current_user.workout_routines.find(params[:id])
    @workout_routine.destroy
    redirect_to workout_routines_path,
                notice: I18n.t("controllers.workout_routines.destroyed")
  end

  def ai_new
    unless current_user.ai_trainer&.configured?
      redirect_to workout_routines_path,
                  alert:
                    I18n.t("controllers.workout_routines.ai_not_configured")
      return
    end

    @muscles = Muscle.order(:name)
  end

  def ai_create
    unless current_user.ai_trainer&.configured?
      redirect_to workout_routines_path,
                  alert:
                    I18n.t("controllers.workout_routines.ai_not_configured")
      return
    end

    if AiLog.where(
         user: current_user,
         created_at: Date.current.all_day
       ).count >= AiClients::Gemini::DAILY_REQUEST_LIMIT
      redirect_to workout_routines_path,
                  alert:
                    I18n.t(
                      "controllers.workout_routines.ai_daily_limit_reached"
                    )
      return
    end

    @workout_routine =
      current_user.workout_routines.create!(
        name: I18n.t("controllers.workout_routines.ai_generating_name"),
        ai_status: :pending
      )

    AiRoutineSuggestionJob.perform_later(
      workout_routine: @workout_routine,
      params: ai_routine_params.to_h.symbolize_keys
    )

    redirect_to @workout_routine,
                notice:
                  I18n.t("controllers.workout_routines.ai_generation_started")
  end

  def ai_status
    @workout_routine = current_user.workout_routines.find(params[:id])
    render json: { status: @workout_routine.ai_status || "completed" }
  end

  private

  def workout_routine_params
    params.require(:workout_routine).permit(:name)
  end

  def ai_routine_params
    params.permit(
      :frequency,
      :split_type,
      :experience_level,
      :additional_context,
      focus_areas: []
    )
  end
end
