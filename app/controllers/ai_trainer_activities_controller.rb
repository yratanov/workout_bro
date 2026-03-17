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

  # POST /ai/:id/ask_ai
  def ask_ai
    @activity = current_user.ai_trainer_activities.find(params[:id])
    question = params[:question].to_s.strip

    if !@activity.completed? || question.blank?
      head :unprocessable_entity
      return
    end

    GenerateAiFollowupJob.perform_later(activity: @activity, question:)
    head :ok
  end
end
