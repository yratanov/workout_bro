# frozen_string_literal: true

class ButtonComponent < ViewComponent::Base
  STYLES = {
    primary: "bg-sky-600 border-sky-600 hover:bg-sky-500 text-slate-100 hover:text-slate-100",
    success: "bg-teal-600 border-teal-600 hover:bg-teal-500 hover:border-teal-500 text-slate-100 hover:text-slate-100",
    danger: "bg-red-400 border-red-400 hover:bg-red-300 hover:border-red-300 text-slate-700",
    warning: "bg-yellow-500 hover:bg-yellow-400 text-slate-100 hover:text-slate-100",
    default: "bg-gray-500 hover:bg-gray-400",
    outlined: "bg-slate-400 border-slate-400 hover:bg-slate-300 text-slate-700",
    link: "text-blue-400 hover:text-blue-300",
    link_danger: "text-red-400 hover:text-red-300",
  }.freeze

  SIZE = { default: "px-8 py-2", lg: "!text-base py-3 px-6" }.freeze

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
      "leading-none disabled:opacity-75 border-gray-650 block text-center whitespace-nowrap select-none focus:border-gray focus:outline-none focus:ring border leading-normal hover:no-underline rounded" unless inline?

    specific_classes = STYLES[@style.to_sym]
    size = SIZE[@size.to_sym] unless inline?

    "#{common_classes} #{specific_classes} #{size} cursor-pointer"
  end

  def inline?
    %w[none link link_danger].include?(@style)
  end
end

