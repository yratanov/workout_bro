# frozen_string_literal: true

class TimerComponent < ViewComponent::Base
  def initialize(started_at:, ended_at:, show_hours: false, paused_at: nil, total_paused_seconds: 0)
    @started_at = started_at
    @ended_at = ended_at
    @show_hours = show_hours
    @paused_at = paused_at
    @total_paused_seconds = total_paused_seconds || 0
  end

  def paused?
    @paused_at.present?
  end
end
