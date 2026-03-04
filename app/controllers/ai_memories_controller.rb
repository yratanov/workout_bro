# frozen_string_literal: true

class AiMemoriesController < ApplicationController
  def index
    @memories = current_user.ai_memories.for_prompt.group_by(&:category)
  end

  def destroy
    memory = current_user.ai_memories.find(params[:id])
    memory.destroy
    redirect_to ai_memories_path,
                notice: I18n.t("controllers.ai_memories.destroyed")
  end

  def generate
    unless current_user.ai_configured? && current_user.ai_trainer&.configured?
      return (
        redirect_to ai_memories_path,
                    alert: I18n.t("controllers.ai_memories.not_configured")
      )
    end

    BootstrapAiMemoriesJob.perform_later(user: current_user)
    @generating = true
    @memories = current_user.ai_memories.for_prompt.group_by(&:category)
    render :index
  end
end
