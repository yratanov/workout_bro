# frozen_string_literal: true

module Settings
  class AiController < ApplicationController
    before_action :set_user

    AI_PROVIDERS = [{ key: "gemini", label: "Google Gemini" }].freeze

    AI_MODELS = {
      "gemini" => %w[gemini-2.5-pro gemini-2.5-flash gemini-2.0-flash]
    }.freeze

    def show
      @providers = AI_PROVIDERS
      @models = AI_MODELS
      @ai_trainer = @user.ai_trainer || @user.build_ai_trainer
    end

    def update
      if @user.update(ai_params)
        redirect_to settings_ai_path,
                    notice: I18n.t("controllers.settings.ai.updated")
      else
        render :show, status: :unprocessable_entity
      end
    end

    def create_trainer
      @ai_trainer = @user.ai_trainer || @user.build_ai_trainer
      @ai_trainer.assign_attributes(ai_trainer_params)
      @ai_trainer.status = :pending

      if @ai_trainer.save
        CreateAiTrainerJob.perform_later(ai_trainer: @ai_trainer)
        redirect_to settings_ai_path,
                    notice: I18n.t("controllers.settings.ai.trainer_created")
      else
        redirect_to settings_ai_path,
                    alert: I18n.t("controllers.settings.ai.trainer_failed")
      end
    end

    def trainer_status
      ai_trainer = @user.ai_trainer
      if ai_trainer
        render json: {
                 status: ai_trainer.status,
                 error_details: ai_trainer.error_details
               }
      else
        render json: { status: "not_found" }
      end
    end

    private

    def set_user
      @user = current_user
    end

    def ai_params
      permitted =
        params.require(:user).permit(:ai_provider, :ai_model, :ai_api_key)
      permitted.delete(:ai_api_key) if permitted[:ai_api_key].blank?
      permitted
    end

    def ai_trainer_params
      params.require(:ai_trainer).permit(
        :approach,
        :communication_style,
        :custom_instructions,
        :goal_build_muscle,
        :goal_lose_weight,
        :goal_improve_endurance,
        :goal_increase_strength,
        :goal_general_fitness,
        :train_on_existing_data
      )
    end
  end
end
