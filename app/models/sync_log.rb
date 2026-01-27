# == Schema Information
#
# Table name: sync_logs
# Database name: primary
#
#  id         :integer          not null, primary key
#  log_type   :integer          default("garmin"), not null
#  message    :text
#  metadata   :json
#  status     :integer          default("success"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_sync_logs_on_created_at  (created_at)
#  index_sync_logs_on_log_type    (log_type)
#  index_sync_logs_on_status      (status)
#  index_sync_logs_on_user_id     (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class SyncLog < ApplicationRecord
  belongs_to :user

  enum :log_type, { garmin: 0 }
  enum :status, { success: 0, failure: 1 }

  validates :log_type, presence: true
  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
