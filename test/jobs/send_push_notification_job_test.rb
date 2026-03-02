require "test_helper"

class SendPushNotificationJobTest < ActiveJob::TestCase
  setup do
    @user = users(:john)
    @notification =
      ScheduledPushNotification.create!(
        user: @user,
        job_id: SecureRandom.uuid,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.from_now
      )

    @mock_service = mock("web_push_service")
    @mock_service.stubs(:send_to_user).returns(
      { sent: 1, failed: 0, expired: 0 }
    )
    WebPushService.stubs(:new).returns(@mock_service)
  end

  test "sends the push notification when notification exists and is pending" do
    PushSubscription.create!(
      user: @user,
      endpoint: "https://example.com/push/123",
      p256dh: "test_key",
      auth: "test_auth"
    )

    @mock_service
      .expects(:send_to_user)
      .once
      .returns({ sent: 1, failed: 0, expired: 0 })

    SendPushNotificationJob.perform_now(@notification.id)
  end

  test "updates notification status to sent" do
    PushSubscription.create!(
      user: @user,
      endpoint: "https://example.com/push/123",
      p256dh: "test_key",
      auth: "test_auth"
    )

    SendPushNotificationJob.perform_now(@notification.id)

    assert @notification.reload.sent?
  end

  test "returns early without error when notification does not exist" do
    assert_nothing_raised { SendPushNotificationJob.perform_now(999_999) }
  end

  test "does not send push when notification is already sent" do
    @notification.update!(status: :sent)

    @mock_service.expects(:send_to_user).never

    SendPushNotificationJob.perform_now(@notification.id)
  end

  test "does not send push when notification is cancelled" do
    @notification.update!(status: :cancelled)

    @mock_service.expects(:send_to_user).never

    SendPushNotificationJob.perform_now(@notification.id)
  end

  test "does not attempt to send when user has no push subscriptions" do
    @mock_service.expects(:send_to_user).never

    SendPushNotificationJob.perform_now(@notification.id)
  end

  test "cancels the notification when VAPID is not configured" do
    WebPushService.stubs(:new).raises(
      WebPushService::ConfigurationError,
      "VAPID keys not configured."
    )

    PushSubscription.create!(
      user: @user,
      endpoint: "https://example.com/push/123",
      p256dh: "test_key",
      auth: "test_auth"
    )

    SendPushNotificationJob.perform_now(@notification.id)

    assert @notification.reload.cancelled?
  end

  test "does not raise an error when VAPID is not configured" do
    WebPushService.stubs(:new).raises(
      WebPushService::ConfigurationError,
      "VAPID keys not configured."
    )

    PushSubscription.create!(
      user: @user,
      endpoint: "https://example.com/push/123",
      p256dh: "test_key",
      auth: "test_auth"
    )

    assert_nothing_raised do
      SendPushNotificationJob.perform_now(@notification.id)
    end
  end
end
