# frozen_string_literal: true

class ButtonComponent < ViewComponent::Base
  STYLES = {
    primary: "text-sky-500 border-sky-500 hover:bg-sky-500 hover:text-slate-100",
    success: "text-teal-500 border-teal-500 hover:bg-teal-500 hover:border-teal-500 hover:text-slate-100",
    danger: " border-red-400 hover:bg-red-400 hover:border-red-400 hover:text-slate-200 text-red-400",
    warning: "bg-yellow-500 hover:bg-yellow-400 text-slate-100 hover:text-slate-100",
    default: "bg-gray-500 hover:bg-gray-400",
    outlined: "border-slate-400 hover:bg-slate-400 text-slate-200",
    link: "text-blue-400 hover:text-blue-300",
    link_danger: "text-red-400 hover:text-red-300",
    link_hover_danger: "text-slate-400 hover:text-red-300",
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
      "leading-none disabled:cursor-not-allowed disabled:opacity-75 border-gray-650 inline-block text-center whitespace-nowrap select-none focus:border-gray focus:outline-none focus:ring border leading-normal hover:no-underline rounded" unless inline?

    specific_classes = STYLES[@style.to_sym]
    size = SIZE[@size.to_sym] unless inline?

    "#{common_classes} #{specific_classes} #{size} cursor-pointer"
  end

  def inline?
    %w[none link link_hover_danger link_danger].include?(@style)
  end
end

