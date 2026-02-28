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
    end

    def update
      if @user.update(ai_params)
        redirect_to settings_ai_path,
                    notice: I18n.t("controllers.settings.ai.updated")
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = current_user
    end

    def ai_params
      params.require(:user).permit(:ai_provider, :ai_model)
    end
  end
end
