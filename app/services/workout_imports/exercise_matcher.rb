module WorkoutImports
  class ExerciseMatcher
    attr_reader :user, :cache

    def initialize(user:)
      @user = user
      @cache = {}
    end

    def match(name)
      return nil if name.blank?

      normalized_name = normalize(name)
      return cache[normalized_name] if cache.key?(normalized_name)

      exercise = find_or_create_exercise(name, normalized_name)
      cache[normalized_name] = exercise
      exercise
    end

    private

    def normalize(name)
      name.to_s.strip.downcase
    end

    def find_or_create_exercise(original_name, normalized_name)
      exercise =
        user.exercises.find { |e| normalize(e.name) == normalized_name }
      return exercise if exercise

      user.exercises.create!(name: original_name.strip)
    end
  end
end
