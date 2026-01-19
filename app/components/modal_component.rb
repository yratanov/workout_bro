# frozen_string_literal: true

class ModalComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(title: nil, open: false, size: "md")
    @title = title
    @open = open
    @size = size
  end

  def size_class
    case @size
    when "sm"
      "max-w-sm"
    when "md"
      "max-w-lg"
    when "lg"
      "max-w-2xl"
    when "xl"
      "max-w-4xl"
    else
      "max-w-lg"
    end
  end

  def open?
    @open
  end
end
