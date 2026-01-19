class AppFormBuilder < ActionView::Helpers::FormBuilder
  delegate :tag, :content_tag, :safe_join, :render, to: :@template

  DEFAULT_INPUT_CLASSES = "w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-3 " \
                          "text-white placeholder-slate-400 " \
                          "focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500".freeze

  def submit(text = "Submit", **options)
    render(
      ButtonComponent.new(style: "success", text:, type: "submit", **options)
    ) { text }
  end

  def input(field, options = {})
    @form_options = options
    object_type = options[:as] || object_type_for_method(field)

    render_field(field, object_type, options)
  end

  def select(method, collection, options = {}, html_options = {})
    super(method, collection, options, html_options)
  end

  def toggle(method, label_text = nil, color: :blue)
    color_classes = {
      blue: "peer-checked:bg-blue-600 peer-focus:ring-blue-500",
      purple: "peer-checked:bg-purple-600 peer-focus:ring-purple-500",
      green: "peer-checked:bg-green-600 peer-focus:ring-green-500"
    }

    tag.label class: "flex items-center gap-3 cursor-pointer" do
      safe_join([
        check_box(method, class: "sr-only peer"),
        tag.span(
          class: "w-10 h-6 bg-slate-700 rounded-full peer #{color_classes[color]} peer-focus:ring-2 " \
                 "relative after:content-[''] after:absolute after:top-0.5 after:left-0.5 " \
                 "after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all " \
                 "peer-checked:after:translate-x-4"
        ),
        tag.span(label_text || object.class.human_attribute_name(method), class: "text-slate-300")
      ])
    end
  end

  private

  def render_field(field, type, options)
    type_to_method = {
      string: :text_field,
      text: :text_area,
      date: :date_field,
      email: :email_field,
      file: :file_field,
      password: :password_field,
      datetime: :datetime_field,
      check_box: :check_box,
      hidden: :hidden_field,
      select: :select,
      editable_text: :editable_text_field,
      rich_textarea: :rich_textarea
    }
    return send(:hidden_field, field) if type == :hidden

    wrap_with_label(field, type, options) do
      default_html = default_input_options(type, error?(field))

      if type == :select
        select_options = { include_blank: options[:include_blank] }
        select_options[:selected] = @object.send(field) if @object.respond_to?(field)
        send(
          :select,
          field,
          options[:collection],
          select_options,
          merge_input_options(default_html, options[:input_html])
        )
      else
        send(
          type_to_method[type],
          field,
          merge_input_options(default_html, options[:input_html])
        )
      end
    end
  end

  def error?(method)
    return false unless @object.respond_to?(:errors)

    @object.errors.key?(method)
  end

  def wrap_with_label(field, type, options = {})
    return yield if options[:inline]

    tag.div class:
              "#{options[:margin] || "mb-4"} #{type == :check_box ? "flex gap-3 items-center" : ""} #{options[:class]} h-full",
            data: options[:data] do
      label =
        if options[:label] != false && type != :editable_text
          label(
            field,
            class:
              "#{type == :check_box ? "" : "mb-2"} block text-sm font-medium #{error?(field) ? "text-red-400" : "text-slate-300"}"
          )
        end

      error =
        if error?(field)
          tag.div class: "text-red-400 text-sm mt-1" do
            @object.errors.messages_for(field).join(", ")
          end
        end

      data =
        if type == :check_box
          [yield, label, error]
        else
          [label, yield, error]
        end

      safe_join(data)
    end
  end

  def editable_text_field(method, options = {})
    ActionView::Helpers::Tags::TextField.new(
      nil,
      method,
      self,
      options.merge(
        object: @object,
        name: "#{object_name}[#{method}]",
        placeholder: true,
        autocomplete: "off",
        class:
          "editable_text_field block w-full border-0 border-b border-slate-600 px-0 py-2 bg-transparent text-2xl font-bold text-white focus:text-slate-200 focus:outline-none !ring-0"
      )
    ).render
  end

  def object_type_for_method(method)
    result =
      if @object.respond_to?(:type_for_attribute) &&
           @object.has_attribute?(method)
        @object.type_for_attribute(method.to_s).try(:type)
      elsif @object.respond_to?(:column_for_attribute) &&
            @object.has_attribute?(method)
        @object.column_for_attribute(method).try(:type)
      end

    result || :string
  end

  def merge_input_options(options, user_options)
    return options if user_options.nil?

    if user_options[:class] && options[:class]
      user_options = user_options.merge(class: "#{options[:class]} #{user_options[:class]}")
    end

    options.merge(user_options)
  end

  def default_input_options(type, has_error)
    return {} if %i[check_box editable_text hidden].include?(type)

    error_classes = has_error ? "border-red-500 focus:border-red-500 focus:ring-red-500" : ""
    { class: "#{DEFAULT_INPUT_CLASSES} #{error_classes}".strip }
  end
end

