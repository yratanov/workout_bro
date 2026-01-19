# frozen_string_literal: true

module Settings
  class GarminController < ApplicationController
    def show
      @credential = current_user.garmin_credential
    end

    def update
      @credential = current_user.garmin_credential
      @credential.assign_attributes(garmin_params)

      if @credential.save
        redirect_to settings_garmin_path, notice: I18n.t("controllers.settings.garmin.updated")
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def garmin_params
      params.require(:third_party_credential).permit(:username, :password)
    end
  end
end
