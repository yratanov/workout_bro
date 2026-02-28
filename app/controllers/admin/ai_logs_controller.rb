# frozen_string_literal: true

module Admin
  class AiLogsController < ApplicationController
    before_action :require_admin

    def index
      @pagination = paginate(AiLog.includes(:user).recent)
    end
  end
end
