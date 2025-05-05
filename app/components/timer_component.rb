# frozen_string_literal: true

class TimerComponent < ViewComponent::Base
  def initialize(started_at:, ended_at:)
    @started_at = started_at
    @ended_at = ended_at
  end
end
