module FormHelpers
  def app_form_with(
    model: false,
    scope: nil,
    url: nil,
    format: nil,
    **options,
    &
  )
    options = options.reverse_merge(builder: AppFormBuilder)
    form_with(model:, scope:, url:, format:, **options, &)
  end

  def text_field(object_name, method, options = {})
    super(object_name, method, options.merge(class: input_class(options)))
  end

  def select(object_name, method, choices, options = {}, html_options = {})
    super(
      object_name,
      method,
      choices,
      options,
      (
        if html_options[:class]
          html_options
        else
          html_options.merge(class: input_class(options))
        end
      )
    )
  end

  def email_field(object_name, method, options = {})
    super(object_name, method, options.merge(class: input_class(options)))
  end

  def password_field(object_name, method, options = {})
    super(object_name, method, options.merge(class: input_class(options)))
  end

  def text_area(object_name, method, options = {})
    super(object_name, method, options.merge(class: input_class(options)))
  end

  def date_field(object_name, method, options = {})
    super(object_name, method, options.merge(class: input_class(options)))
  end

  def datetime_field(object_name, method, options = {})
    super(object_name, method, options.merge(class: input_class(options)))
  end

  private

  def input_class(options)
    "block rounded-lg border bg-slate-800 px-4 py-3 text-white placeholder-slate-500 " \
      "focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none " \
      "#{options[:width] || "w-full"} " \
      "#{options[:disabled] ? "bg-slate-900 cursor-not-allowed opacity-50" : ""} " \
      "#{options[:error] ? "border-red-500" : "border-slate-600"}"
  end
end
