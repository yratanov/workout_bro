# frozen_string_literal: true

module Admin
  class UsersController < ApplicationController
    before_action :require_admin
    before_action :set_user, only: %i[edit update destroy]

    def index
      @users = User.order(created_at: :desc)
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_users_path,
                    notice: I18n.t("controllers.admin.users.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path,
                    alert: I18n.t("controllers.admin.users.cannot_delete_self")
        return
      end

      @user.destroy!
      redirect_to admin_users_path,
                  notice: I18n.t("controllers.admin.users.destroyed")
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:email_address)
    end
  end
end
