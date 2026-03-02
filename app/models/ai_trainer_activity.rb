# frozen_string_literal: true

# == Schema Information
#
# Table name: ai_trainer_activities
# Database name: primary
#
#  id            :integer          not null, primary key
#  activity_type :integer          not null
#  content       :text
#  error_message :text
#  status        :integer          default("pending"), not null
#  viewed_at     :datetime
#  week_start    :date
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  ai_trainer_id :integer
#  user_id       :integer          not null
#  workout_id    :integer
#
# Indexes
#
#  idx_activities_trainer_type_created                       (ai_trainer_id,activity_type,created_at)
#  index_ai_trainer_activities_on_user_id_and_activity_type  (user_id,activity_type)
#  index_ai_trainer_activities_on_user_id_and_created_at     (user_id,created_at)
#  index_ai_trainer_activities_on_workout_id                 (workout_id) UNIQUE
#
# Foreign Keys
#
#  ai_trainer_id  (ai_trainer_id => ai_trainers.id)
#  user_id        (user_id => users.id)
#  workout_id     (workout_id => workouts.id)
#
class AiTrainerActivity < ApplicationRecord
  belongs_to :user
  belongs_to :ai_trainer, optional: true
  belongs_to :workout, optional: true

  enum :activity_type, { full_review: 0, workout_review: 1, weekly_report: 2 }
  enum :status, { pending: 0, completed: 1, failed: 2 }

  validates :activity_type, presence: true
  validates :workout_id, uniqueness: true, allow_nil: true

  scope :recent, -> { order(created_at: :desc) }
  scope :unviewed, -> { completed.where(viewed_at: nil) }

  def viewed?
    viewed_at.present?
  end
end
