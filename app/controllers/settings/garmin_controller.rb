# frozen_string_literal: true

module Settings
  class GarminController < ApplicationController
    def show
      @credential = current_user.garmin_credential
      @sync_logs = current_user.sync_logs.recent.limit(50)
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

    def sync
      service = GarminSyncService.new(user: current_user)
      result = service.call

      redirect_to settings_garmin_path,
        notice: I18n.t("controllers.settings.garmin.sync_success",
          imported: result[:imported],
          skipped: result[:skipped])
    rescue GarminSyncService::MissingCredentialsError
      redirect_to settings_garmin_path,
        alert: I18n.t("controllers.settings.garmin.missing_credentials")
    rescue GarminSyncService::Error => e
      redirect_to settings_garmin_path,
        alert: I18n.t("controllers.settings.garmin.sync_failed", error: e.message)
    end

    private

    def garmin_params
      params.require(:third_party_credential).permit(:username, :password)
    end
  end
end
