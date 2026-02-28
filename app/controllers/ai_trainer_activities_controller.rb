# frozen_string_literal: true

class AiTrainerActivitiesController < ApplicationController
  def index
    @activities =
      current_user.ai_trainer_activities.completed.recent.includes(:workout)
  end

  def show
    @activity = current_user.ai_trainer_activities.find(params[:id])
    @activity.update!(viewed_at: Time.current) unless @activity.viewed?
  end
end
