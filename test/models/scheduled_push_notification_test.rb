require "test_helper"

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

class ScheduledPushNotificationTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    notification =
      ScheduledPushNotification.new(
        user: users(:john),
        job_id: SecureRandom.uuid,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.from_now
      )
    assert notification.valid?
  end

  test "is invalid without job_id" do
    notification =
      ScheduledPushNotification.new(
        user: users(:john),
        job_id: nil,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.from_now
      )
    assert_not notification.valid?
    assert_includes notification.errors[:job_id], "can't be blank"
  end

  test "is invalid without notification_type" do
    notification =
      ScheduledPushNotification.new(
        user: users(:john),
        job_id: SecureRandom.uuid,
        notification_type: nil,
        scheduled_for: 1.minute.from_now
      )
    assert_not notification.valid?
    assert_includes notification.errors[:notification_type], "can't be blank"
  end

  test "is invalid without scheduled_for" do
    notification =
      ScheduledPushNotification.new(
        user: users(:john),
        job_id: SecureRandom.uuid,
        notification_type: "rest_timer",
        scheduled_for: nil
      )
    assert_not notification.valid?
    assert_includes notification.errors[:scheduled_for], "can't be blank"
  end

  test "enforces unique job_id" do
    job_id = SecureRandom.uuid
    ScheduledPushNotification.create!(
      user: users(:john),
      job_id: job_id,
      notification_type: "rest_timer",
      scheduled_for: 1.minute.from_now
    )

    duplicate =
      ScheduledPushNotification.new(
        user: users(:john),
        job_id: job_id,
        notification_type: "rest_timer",
        scheduled_for: 2.minutes.from_now
      )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:job_id], "has already been taken"
  end

  test "defaults to pending status" do
    notification =
      ScheduledPushNotification.create!(
        user: users(:john),
        job_id: SecureRandom.uuid,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.from_now
      )
    assert notification.pending?
  end

  test "can be set to sent" do
    notification =
      ScheduledPushNotification.create!(
        user: users(:john),
        job_id: SecureRandom.uuid,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.from_now,
        status: :sent
      )
    assert notification.sent?
  end

  test "can be set to cancelled" do
    notification =
      ScheduledPushNotification.create!(
        user: users(:john),
        job_id: SecureRandom.uuid,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.from_now,
        status: :cancelled
      )
    assert notification.cancelled?
  end

  test "cancel! updates status to cancelled when pending" do
    notification =
      ScheduledPushNotification.create!(
        user: users(:john),
        job_id: SecureRandom.uuid,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.from_now
      )
    notification.cancel!
    assert notification.reload.cancelled?
  end

  test "cancel! does not change status when already sent" do
    notification =
      ScheduledPushNotification.create!(
        user: users(:john),
        job_id: SecureRandom.uuid,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.from_now
      )
    notification.update!(status: :sent)
    notification.cancel!
    assert notification.reload.sent?
  end

  test "cancel! does not change status when already cancelled" do
    notification =
      ScheduledPushNotification.create!(
        user: users(:john),
        job_id: SecureRandom.uuid,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.from_now
      )
    notification.update!(status: :cancelled)
    notification.cancel!
    assert notification.reload.cancelled?
  end

  test "pending scope returns only pending notifications" do
    pending_notification =
      ScheduledPushNotification.create!(
        user: users(:john),
        job_id: SecureRandom.uuid,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.from_now,
        status: :pending
      )

    ScheduledPushNotification.create!(
      user: users(:john),
      job_id: SecureRandom.uuid,
      notification_type: "rest_timer",
      scheduled_for: 1.minute.from_now,
      status: :sent
    )

    assert_equal [pending_notification], ScheduledPushNotification.pending
  end

  test "cancel! destroys the SolidQueue job when it exists" do
    notification =
      ScheduledPushNotification.create!(
        user: users(:john),
        job_id: SecureRandom.uuid,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.from_now
      )

    mock_job = mock("solid_queue_job")
    mock_job.expects(:destroy).once

    SolidQueue::Job.stubs(:table_exists?).returns(true)
    SolidQueue::Job
      .stubs(:find_by)
      .with(active_job_id: notification.job_id)
      .returns(mock_job)

    notification.cancel!

    assert notification.reload.cancelled?
  end

  test "cancel! handles missing SolidQueue job gracefully" do
    notification =
      ScheduledPushNotification.create!(
        user: users(:john),
        job_id: SecureRandom.uuid,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.from_now
      )

    SolidQueue::Job.stubs(:table_exists?).returns(true)
    SolidQueue::Job
      .stubs(:find_by)
      .with(active_job_id: notification.job_id)
      .returns(nil)

    notification.cancel!

    assert notification.reload.cancelled?
  end

  test "cancel! handles ActiveRecord::StatementInvalid gracefully" do
    notification =
      ScheduledPushNotification.create!(
        user: users(:john),
        job_id: SecureRandom.uuid,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.from_now
      )

    SolidQueue::Job.stubs(:table_exists?).returns(true)
    SolidQueue::Job.stubs(:find_by).raises(
      ActiveRecord::StatementInvalid,
      "table not found"
    )

    notification.cancel!

    assert notification.reload.cancelled?
  end
end
