# frozen_string_literal: true

module Settings
  class LogsController < ApplicationController
    def show
      @sync_logs = current_user.sync_logs.recent.limit(50)
    end
  end
end
