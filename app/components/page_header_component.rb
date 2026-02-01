# frozen_string_literal: true

class PageHeaderComponent < ViewComponent::Base
  def initialize(title:)
    @title = title
  end

  attr_reader :title
end
