class SetupController < ApplicationController
  STEPS = %w[account language exercises garmin complete].freeze

  allow_unauthenticated_access only: %i[show update]
  before_action :require_setup_access
  before_action :set_current_step

  def show
    render current_step_template
  end

  def update
    case @current_step
    when "account"
      handle_account_step
    when "language"
      handle_language_step
    when "exercises"
      handle_exercises_step
    when "garmin"
      handle_garmin_step
    when "complete"
      handle_complete_step
    end
  end

  private

  def require_setup_access
    if User.count == 0
      return true
    end

    return redirect_to root_path if authenticated? && Current.user.setup_completed?

    resume_session || request_authentication
  end

  def set_current_step
    @current_step = if User.count == 0
      "account"
    elsif authenticated?
      STEPS[Current.user.wizard_step] || "complete"
    else
      "account"
    end
  end

  def current_step_template
    @current_step
  end

  def handle_account_step
    @user = User.new(account_params)
    if @user.save
      start_new_session_for(@user)
      advance_to_step(1)
      redirect_to setup_path
    else
      render :account, status: :unprocessable_entity
    end
  end

  def handle_language_step
    if Current.user.update(locale: params[:locale])
      advance_to_step(2)
      redirect_to setup_path
    else
      render :language, status: :unprocessable_entity
    end
  end

  def handle_exercises_step
    if params[:import_exercises] == "1"
      ExercisesImportJob.perform_later
    end
    advance_to_step(3)
    redirect_to setup_path
  end

  def handle_garmin_step
    if params[:skip] == "1"
      advance_to_step(4)
      redirect_to setup_path
    else
      credential = Current.user.garmin_credential
      credential.assign_attributes(garmin_params)
      if credential.save
        advance_to_step(4)
        redirect_to setup_path
      else
        @credential = credential
        render :garmin, status: :unprocessable_entity
      end
    end
  end

  def handle_complete_step
    Current.user.update!(setup_completed: true)

    redirect_path = case params[:next_path]
    when "workout"
      new_workout_path
    when "routine"
      new_workout_routine_path
    else
      root_path
    end

    redirect_to redirect_path, notice: I18n.t("controllers.setup.completed")
  end

  def advance_to_step(step)
    Current.user.update!(wizard_step: step)
  end

  def account_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end

  def garmin_params
    params.require(:third_party_credential).permit(:username, :password)
  end
end
