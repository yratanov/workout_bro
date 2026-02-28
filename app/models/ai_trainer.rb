# frozen_string_literal: true

# == Schema Information
#
# Table name: ai_trainers
# Database name: primary
#
#  id                     :integer          not null, primary key
#  approach               :integer          default("balanced"), not null
#  communication_style    :integer          default("motivational"), not null
#  custom_instructions    :string
#  error_details          :json
#  goal_build_muscle      :boolean          default(FALSE), not null
#  goal_general_fitness   :boolean          default(TRUE), not null
#  goal_improve_endurance :boolean          default(FALSE), not null
#  goal_increase_strength :boolean          default(FALSE), not null
#  goal_lose_weight       :boolean          default(FALSE), not null
#  status                 :integer          default("pending"), not null
#  summary                :text
#  system_prompt          :text
#  train_on_existing_data :boolean          default(TRUE), not null
#  trainer_profile        :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  user_id                :integer          not null
#
# Indexes
#
#  index_ai_trainers_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id) ON DELETE => cascade
#
class AiTrainer < ApplicationRecord
  belongs_to :user
  has_many :ai_trainer_activities, dependent: :destroy

  enum :approach, { supportive: 0, tough_love: 1, balanced: 2 }
  enum :communication_style, { concise: 0, detailed: 1, motivational: 2 }
  enum :status, { pending: 0, in_progress: 1, completed: 2, failed: 3 }

  GOALS = %i[
    goal_build_muscle
    goal_lose_weight
    goal_improve_endurance
    goal_increase_strength
    goal_general_fitness
  ].freeze

  def processing?
    pending? || in_progress?
  end

  def configured?
    completed? && trainer_profile.present?
  end

  def goals
    GOALS.select { |g| send(g) }
  end

  def latest_full_review
    ai_trainer_activities.full_review.completed.order(created_at: :desc).first
  end

  def activities_since_last_review
    review = latest_full_review
    scope = ai_trainer_activities.completed.order(:created_at)
    scope = scope.where("created_at > ?", review.created_at) if review
    scope
  end

  def weekly_reports_since_last_review_count
    review = latest_full_review
    scope = ai_trainer_activities.weekly_report.completed
    scope = scope.where("created_at > ?", review.created_at) if review
    scope.count
  end
end
