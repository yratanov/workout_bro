# frozen_string_literal: true

class StatCardComponent < ViewComponent::Base
  def initialize(label:, size: :lg)
    @label = label
    @size = size
  end

  def card_classes
    base = "rounded-lg text-center"
    case @size
    when :sm
      "#{base} bg-slate-700 p-3"
    else
      "#{base} bg-slate-800 p-4"
    end
  end

  def label_classes
    base = "text-slate-400 mb-1"
    case @size
    when :sm
      "#{base} text-xs"
    else
      "#{base} text-sm"
    end
  end

  def value_classes
    base = "font-bold text-white"
    case @size
    when :sm
      "#{base} text-lg"
    else
      "#{base} text-2xl"
    end
  end
end
