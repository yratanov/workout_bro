# == Schema Information
#
# Table name: workout_imports
# Database name: primary
#
#  id                :integer          not null, primary key
#  error_details     :json
#  imported_count    :integer          default(0), not null
#  original_filename :string
#  skipped_count     :integer          default(0), not null
#  status            :integer          default("pending"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :integer          not null
#
# Indexes
#
#  index_workout_imports_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class WorkoutImport < ApplicationRecord
  belongs_to :user
  has_many :workouts, dependent: :nullify

  has_one_attached :file

  enum :status, { pending: 0, in_progress: 1, completed: 2, failed: 3 }

  validates :status, presence: true
  validates :file, presence: true
  validate :file_must_be_csv

  private

  def file_must_be_csv
    return unless file.attached?

    unless file.content_type == "text/csv" ||
             file.filename.to_s.end_with?(".csv")
      errors.add(:file, :invalid_format)
    end
  end
end
