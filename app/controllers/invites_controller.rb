# frozen_string_literal: true

class InvitesController < ApplicationController
  allow_unauthenticated_access
  before_action :require_unauthenticated
  before_action :set_invite

  def show
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      @invite.update!(used_by_user: @user, used_at: Time.current)
      start_new_session_for(@user)
      @user.update!(wizard_step: 1)
      redirect_to setup_path
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def require_unauthenticated
    redirect_to root_path if authenticated?
  end

  def set_invite
    @invite = Invite.find_by!(token: params[:token])

    if @invite.used?
      redirect_to new_session_path, alert: I18n.t("controllers.invites.already_used")
    end
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
