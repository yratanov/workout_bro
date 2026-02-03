# == Schema Information
#
# Table name: scheduled_push_notifications
# Database name: primary
#
#  id                :integer          not null, primary key
#  notification_type :string           not null
#  scheduled_for     :datetime         not null
#  status            :string           default("pending"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  job_id            :string           not null
#  user_id           :integer          not null
#
# Indexes
#
#  index_scheduled_push_notifications_on_job_id   (job_id) UNIQUE
#  index_scheduled_push_notifications_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class ScheduledPushNotification < ApplicationRecord
  belongs_to :user

  enum :status, { pending: "pending", sent: "sent", cancelled: "cancelled" }

  validates :job_id, presence: true, uniqueness: true
  validates :notification_type, presence: true
  validates :scheduled_for, presence: true

  scope :pending, -> { where(status: :pending) }

  def cancel!
    return unless pending?

    begin
      if defined?(SolidQueue::Job) && SolidQueue::Job.table_exists?
        job = SolidQueue::Job.find_by(active_job_id: job_id)
        job&.destroy
      end
    rescue ActiveRecord::StatementInvalid
      # SolidQueue tables may not exist in test environment
    end

    update!(status: :cancelled)
  end
end
