# frozen_string_literal: true

module Settings
  class ProfileController < ApplicationController
    before_action :set_user

    def show
    end

    def update
      if @user.update(profile_params)
        redirect_to settings_profile_path, notice: I18n.t("controllers.settings.profile.updated")
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = current_user
    end

    def profile_params
      params.require(:user).permit(:email_address, :locale)
    end
  end
end
