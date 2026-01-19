class MusclesSeeder
  MUSCLES = %w[chest back shoulders biceps triceps legs glutes core].freeze

  def call
    created = 0
    skipped = 0

    MUSCLES.each do |name|
      muscle = Muscle.find_or_initialize_by(name: name)
      if muscle.new_record?
        muscle.save!
        created += 1
      else
        skipped += 1
      end
    end

    { created: created, skipped: skipped }
  end
end
