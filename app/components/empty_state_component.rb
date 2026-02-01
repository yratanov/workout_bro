# frozen_string_literal: true

class EmptyStateComponent < ViewComponent::Base
  def initialize(message:, icon: nil, emoji: nil, title: nil, hint: nil)
    @message = message
    @icon = icon
    @emoji = emoji
    @title = title
    @hint = hint
  end

  attr_reader :message, :icon, :emoji, :title, :hint
end
