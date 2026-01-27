# frozen_string_literal: true

module WorkoutImportHelpers
  def create_workout_import(user:, **attrs)
    skip_file = attrs.delete(:skip_file)
    import = WorkoutImport.new(user: user, **attrs)
    unless skip_file
      import.file.attach(
        io: StringIO.new("test,data"),
        filename: "test.csv",
        content_type: "text/csv"
      )
    end
    if skip_file
      import.save!(validate: false)
    else
      import.save!
    end
    import
  end
end

RSpec.configure do |config|
  config.include WorkoutImportHelpers
end
