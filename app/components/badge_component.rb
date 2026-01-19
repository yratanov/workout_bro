# frozen_string_literal: true

class BadgeComponent < ViewComponent::Base
  def initialize(variant: "default", size: "md")
    @variant = variant
    @size = size
  end

  def size_class
    case @size
    when "sm"
      "text-xs px-2 py-1"
    when "md"
      "text-sm px-3 py-1"
    when "lg"
      "text-base px-4 py-2"
    else
      "text-sm px-2 py-2" # default size
    end
  end
end
