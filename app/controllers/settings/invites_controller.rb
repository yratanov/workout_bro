# frozen_string_literal: true

module Settings
  class InvitesController < ApplicationController
    before_action :require_admin
    before_action :set_invite, only: :destroy

    def show
      @invites = current_user.invites.order(created_at: :desc)
    end

    def create
      @invite = current_user.invites.create!
      redirect_to settings_invites_path, notice: I18n.t("controllers.settings.invites.created")
    end

    def destroy
      @invite.destroy!
      redirect_to settings_invites_path, notice: I18n.t("controllers.settings.invites.destroyed")
    end

    private

    def set_invite
      @invite = current_user.invites.find(params[:id])
    end
  end
end
