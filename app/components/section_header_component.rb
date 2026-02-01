# frozen_string_literal: true

class SectionHeaderComponent < ViewComponent::Base
  def initialize(title:, icon: nil, icon_class: nil, title_class: nil)
    @title = title
    @icon = icon
    @icon_class = icon_class || "text-slate-400"
    @title_class = title_class || "text-slate-400 font-semibold"
  end

  attr_reader :title, :icon, :icon_class, :title_class
end
