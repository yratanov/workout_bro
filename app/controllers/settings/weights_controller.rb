# frozen_string_literal: true

module Settings
  class WeightsController < ApplicationController
    before_action :set_user

    def show
    end

    def update
      if @user.update(weights_params)
        redirect_to settings_weights_path,
                    notice: I18n.t("controllers.settings.weights.updated")
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = current_user
    end

    def weights_params
      params.require(:user).permit(
        :weight_unit,
        :weight_min,
        :weight_max,
        :weight_step
      )
    end
  end
end
