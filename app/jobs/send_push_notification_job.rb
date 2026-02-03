class SendPushNotificationJob < ApplicationJob
  queue_as :default

  def perform(scheduled_notification_id)
    notification = ScheduledPushNotification.find_by(id: scheduled_notification_id)
    return unless notification
    return unless notification.pending?

    user = notification.user
    return unless user.push_subscriptions.any?

    service = WebPushService.new
    service.send_to_user(
      user: user,
      title: I18n.t("push_notifications.rest_timer.title"),
      body: I18n.t("push_notifications.rest_timer.body"),
      data: {
        tag: "rest-timer-#{notification.id}",
        path: "/"
      }
    )

    notification.update!(status: :sent)
  rescue WebPushService::ConfigurationError => e
    Rails.logger.error("WebPush configuration error: #{e.message}")
    notification.update!(status: :cancelled)
  end
end
