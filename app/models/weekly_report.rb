# frozen_string_literal: true

# == Schema Information
#
# Table name: weekly_reports
# Database name: primary
#
#  id            :integer          not null, primary key
#  ai_summary    :text
#  error_message :text
#  status        :integer          default("pending"), not null
#  viewed_at     :datetime
#  week_start    :date             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :integer          not null
#
# Indexes
#
#  index_weekly_reports_on_user_id                 (user_id)
#  index_weekly_reports_on_user_id_and_week_start  (user_id,week_start) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class WeeklyReport < ApplicationRecord
  belongs_to :user

  enum :status, { pending: 0, completed: 1, failed: 2 }

  scope :recent, -> { order(week_start: :desc) }
  scope :unviewed, -> { completed.where(viewed_at: nil) }

  def viewed?
    viewed_at.present?
  end
end
