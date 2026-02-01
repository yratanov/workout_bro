# frozen_string_literal: true

module Admin
  class LogsController < ApplicationController
    before_action :require_admin

    def show
      @pagination = paginate(ErrorLog.recent)
    end
  end
end
