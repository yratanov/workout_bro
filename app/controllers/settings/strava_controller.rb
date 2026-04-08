# frozen_string_literal: true

module Settings
  class StravaController < ApplicationController
    def show
      @credential = current_user.strava_credential
      @sync_logs =
        current_user.sync_logs.where(log_type: :strava).recent.limit(50)
    end

    def connect
      oauth = StravaOauthService.new
      redirect_to oauth.authorize_url(
                    redirect_uri: callback_settings_strava_url
                  ),
                  allow_other_host: true
    end

    def callback
      credential = current_user.strava_credential
      oauth = StravaOauthService.new
      oauth.exchange_code(
        code: params[:code],
        credential: credential,
        redirect_uri: callback_settings_strava_url
      )

      redirect_to settings_strava_path,
                  notice: I18n.t("controllers.settings.strava.connected")
    rescue StravaOauthService::Error => e
      redirect_to settings_strava_path,
                  alert:
                    I18n.t(
                      "controllers.settings.strava.oauth_error",
                      error: e.message
                    )
    end

    def disconnect
      credential = current_user.strava_credential
      if credential.persisted?
        begin
          StravaOauthService.new.deauthorize(credential)
        rescue StandardError
          nil
        end
        credential.destroy
      end

      redirect_to settings_strava_path,
                  notice: I18n.t("controllers.settings.strava.disconnected")
    end

    def toggle_sync
      credential = current_user.strava_credential
      credential.update!(sync_enabled: !credential.sync_enabled?)

      redirect_to settings_strava_path,
                  notice:
                    I18n.t(
                      "controllers.settings.strava.sync_toggled",
                      status:
                        I18n.t(
                          "controllers.settings.shared.sync_status.#{credential.sync_enabled? ? "enabled" : "disabled"}"
                        )
                    )
    end

    def sync
      service = StravaSyncService.new(user: current_user)
      result = service.call

      redirect_to settings_strava_path,
                  notice:
                    I18n.t(
                      "controllers.settings.strava.sync_success",
                      imported: result[:imported],
                      skipped: result[:skipped]
                    )
    rescue StravaSyncService::MissingCredentialsError
      redirect_to settings_strava_path,
                  alert:
                    I18n.t("controllers.settings.strava.missing_credentials")
    rescue StravaSyncService::Error => e
      redirect_to settings_strava_path,
                  alert:
                    I18n.t(
                      "controllers.settings.strava.sync_failed",
                      error: e.message
                    )
    end
  end
end
