require "test_helper"

class ScheduledPushNotificationsTest < ActionDispatch::IntegrationTest
  setup { @user = users(:john) }

  # === POST /scheduled_push_notifications (authenticated, valid delay) ===

  test "POST /scheduled_push_notifications creates a scheduled notification" do
    sign_in(@user)
    assert_difference "ScheduledPushNotification.count", 1 do
      post scheduled_push_notifications_path,
           params: {
             delay_seconds: 60
           },
           as: :json
    end
  end

  test "POST /scheduled_push_notifications returns created status" do
    sign_in(@user)
    post scheduled_push_notifications_path,
         params: {
           delay_seconds: 60
         },
         as: :json
    assert_response :created
  end

  test "POST /scheduled_push_notifications returns the notification id" do
    sign_in(@user)
    post scheduled_push_notifications_path,
         params: {
           delay_seconds: 60
         },
         as: :json
    assert response.parsed_body["id"].present?
  end

  test "POST /scheduled_push_notifications returns the scheduled_for time" do
    sign_in(@user)
    post scheduled_push_notifications_path,
         params: {
           delay_seconds: 60
         },
         as: :json
    scheduled_for = Time.zone.parse(response.parsed_body["scheduled_for"])
    assert_in_delta (Time.current + 60.seconds).to_f, scheduled_for.to_f, 2
  end

  test "POST /scheduled_push_notifications enqueues a job" do
    sign_in(@user)
    assert_enqueued_with(job: SendPushNotificationJob) do
      post scheduled_push_notifications_path,
           params: {
             delay_seconds: 60
           },
           as: :json
    end
  end

  test "POST /scheduled_push_notifications returns error for zero delay" do
    sign_in(@user)
    post scheduled_push_notifications_path,
         params: {
           delay_seconds: 0
         },
         as: :json
    assert_response :unprocessable_entity
    assert_equal "Invalid delay", response.parsed_body["error"]
  end

  test "POST /scheduled_push_notifications returns error for negative delay" do
    sign_in(@user)
    post scheduled_push_notifications_path,
         params: {
           delay_seconds: -10
         },
         as: :json
    assert_response :unprocessable_entity
  end

  test "POST /scheduled_push_notifications redirects when not authenticated" do
    post scheduled_push_notifications_path,
         params: {
           delay_seconds: 60
         },
         as: :json
    assert_response :redirect
  end

  # === DELETE /scheduled_push_notifications/:id ===

  test "DELETE /scheduled_push_notifications/:id cancels the notification" do
    sign_in(@user)
    notification = create_pending_notification(@user)
    delete scheduled_push_notification_path(notification), as: :json
    assert notification.reload.cancelled?
  end

  test "DELETE /scheduled_push_notifications/:id returns success status" do
    sign_in(@user)
    notification = create_pending_notification(@user)
    delete scheduled_push_notification_path(notification), as: :json
    assert_response :ok
    assert_equal "cancelled", response.parsed_body["status"]
  end

  test "DELETE /scheduled_push_notifications/:id returns not found for already sent notification" do
    sign_in(@user)
    notification =
      ScheduledPushNotification.create!(
        user: @user,
        job_id: SecureRandom.uuid,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.ago,
        status: :sent
      )
    delete scheduled_push_notification_path(notification), as: :json
    assert_response :not_found
  end

  test "DELETE /scheduled_push_notifications/:id returns not found for other user's notification" do
    sign_in(@user)
    other_user = users(:jane)
    notification = create_pending_notification(other_user)
    delete scheduled_push_notification_path(notification), as: :json
    assert_response :not_found
  end

  test "DELETE /scheduled_push_notifications/:id returns not found for nonexistent notification" do
    sign_in(@user)
    delete scheduled_push_notification_path(id: 999_999), as: :json
    assert_response :not_found
  end

  # === DELETE /scheduled_push_notifications/cancel_all ===

  test "DELETE /scheduled_push_notifications/cancel_all cancels all pending notifications" do
    sign_in(@user)
    notification1 = create_pending_notification(@user)
    notification2 =
      create_pending_notification(@user, scheduled_for: 2.minutes.from_now)

    delete cancel_all_scheduled_push_notifications_path, as: :json

    assert notification1.reload.cancelled?
    assert notification2.reload.cancelled?
  end

  test "DELETE /scheduled_push_notifications/cancel_all returns success status" do
    sign_in(@user)
    create_pending_notification(@user)
    delete cancel_all_scheduled_push_notifications_path, as: :json
    assert_response :ok
    assert_equal "cancelled", response.parsed_body["status"]
  end

  test "DELETE /scheduled_push_notifications/cancel_all with no pending notifications returns success" do
    sign_in(@user)
    delete cancel_all_scheduled_push_notifications_path, as: :json
    assert_response :ok
  end

  test "DELETE /scheduled_push_notifications/cancel_all does not cancel other user's notifications" do
    sign_in(@user)
    other_user = users(:jane)
    other_notification = create_pending_notification(other_user)
    delete cancel_all_scheduled_push_notifications_path, as: :json
    assert other_notification.reload.pending?
  end

  private

  def create_pending_notification(user, scheduled_for: 1.minute.from_now)
    ScheduledPushNotification.create!(
      user: user,
      job_id: SecureRandom.uuid,
      notification_type: "rest_timer",
      scheduled_for: scheduled_for,
      status: :pending
    )
  end
end
