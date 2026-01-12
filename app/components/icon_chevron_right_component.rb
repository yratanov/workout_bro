# frozen_string_literal: true

class IconChevronRightComponent < ViewComponent::Base
  def initialize(size: nil)
    @size = size || 'w-6 h-6'
  end
end
