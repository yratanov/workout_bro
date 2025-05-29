# frozen_string_literal: true

class IconStopwatchComponent < ViewComponent::Base
  def initialize(size: nil)
    @size = size || 'w-4 h-4'
  end
end
