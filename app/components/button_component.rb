# frozen_string_literal: true

class ButtonComponent < ViewComponent::Base
  STYLES = {
    primary:
      "bg-blue-600 hover:bg-blue-500 text-white shadow-lg hover:shadow-blue-500/25",
    success:
      "bg-emerald-600 hover:bg-emerald-500 text-white shadow-lg hover:shadow-emerald-500/25",
    danger:
      "bg-red-600 hover:bg-red-500 text-white shadow-lg hover:shadow-red-500/25",
    warning:
      "bg-amber-500 hover:bg-amber-400 text-white shadow-lg hover:shadow-amber-500/25",
    default:
      "bg-slate-600 hover:bg-slate-500 text-white shadow-lg hover:shadow-slate-500/25",
    outlined:
      "bg-transparent border-2 border-slate-500 hover:border-slate-400 hover:bg-slate-700 text-slate-200",
    link: "text-blue-400 hover:text-blue-300",
    link_danger: "text-red-400 hover:text-red-300",
    link_hover_danger: "text-slate-400 hover:text-red-400"
  }.freeze

  SIZE = { default: "px-6 py-2.5", lg: "px-8 py-3 text-base" }.freeze

  def initialize(
    style: "default",
    size: "default",
    type: "button",
    text: "",
    route: nil,
    data: {},
    **options
  )
    @style = style
    @size = size
    @type = type
    @text = text
    @route = route
    @data = data
    @options = options
  end

  def classes
    common_classes =
      "font-semibold rounded-lg transition inline-block text-center whitespace-nowrap select-none focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-slate-900 focus:ring-blue-500 hover:no-underline disabled:cursor-not-allowed disabled:opacity-50" unless inline?

    specific_classes = STYLES[@style.to_sym]
    size = SIZE[@size.to_sym] unless inline?

    "#{common_classes} #{specific_classes} #{size} cursor-pointer"
  end

  def inline?
    %w[none link link_hover_danger link_danger].include?(@style)
  end
end
