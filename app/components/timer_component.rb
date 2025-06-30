# frozen_string_literal: true

class TimerComponent < ViewComponent::Base
  def initialize(started_at:, ended_at:, show_hours: false)
    @started_at = started_at
    @ended_at = ended_at
    @show_hours = show_hours
  end
end
