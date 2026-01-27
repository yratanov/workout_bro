# frozen_string_literal: true

module Settings
  class LogsController < ApplicationController
    before_action :require_admin

    def show
      @error_logs = ErrorLog.recent.limit(100)
    end
  end
end
