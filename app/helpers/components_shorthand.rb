module ComponentsShorthand
  extend ActiveSupport::Concern

  included do
    def self.components(*names)
      names.each do |name|
        define_method(name) do |*args, **options, &block|
          render("#{name}_component".camelize.constantize.new(**options)) do
            block ? block.call : args.first
          end
        end
      end
    end
  end
end
