# frozen_string_literal: true

class WeeklyReportsController < ApplicationController
  def index
    @weekly_reports = current_user.weekly_reports.recent
  end

  def show
    @weekly_report = current_user.weekly_reports.find(params[:id])
    unless @weekly_report.viewed?
      @weekly_report.update!(viewed_at: Time.current)
    end
  end
end
