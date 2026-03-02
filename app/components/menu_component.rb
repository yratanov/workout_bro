# frozen_string_literal: true

class MenuComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(items:, current_page:, translation_namespace:)
    @items = items
    @current_page = current_page
    @translation_namespace = translation_namespace
  end

  private

  def active?(key)
    @current_page == key
  end

  def item_classes(key)
    base = "flex items-center gap-3 px-4 py-3 rounded-lg transition-colors"
    if active?(key)
      "#{base} bg-slate-700 text-white"
    else
      "#{base} text-slate-400 hover:bg-slate-700/50 hover:text-white"
    end
  end
end
