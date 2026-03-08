# frozen_string_literal: true

module WorkoutBro
  VERSION = File.read(Rails.root.join("VERSION")).strip.freeze
  REVISION = if File.exist?(Rails.root.join("REVISION"))
    File.read(Rails.root.join("REVISION")).strip.freeze
  end

  def self.version_string
    REVISION ? "#{VERSION} (#{REVISION})" : VERSION
  end
end
