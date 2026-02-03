class ScheduledPushNotificationsController < ApplicationController
  before_action :require_authentication

  def create
    delay_seconds = params[:delay_seconds].to_i
    if delay_seconds <= 0
      return (
        render json: { error: "Invalid delay" }, status: :unprocessable_entity
      )
    end

    scheduled_for = Time.current + delay_seconds.seconds
    job_id = SecureRandom.uuid

    notification =
      current_user.scheduled_push_notifications.create!(
        job_id: job_id,
        notification_type: "rest_timer",
        scheduled_for: scheduled_for,
        status: :pending
      )

    SendPushNotificationJob.set(wait: delay_seconds.seconds).perform_later(
      notification.id
    )

    render json: {
             id: notification.id,
             scheduled_for: notification.scheduled_for.iso8601
           },
           status: :created
  end

  def destroy
    notification =
      current_user.scheduled_push_notifications.pending.find_by(id: params[:id])

    if notification
      notification.cancel!
      render json: { status: "cancelled" }
    else
      render json: { status: "not_found" }, status: :not_found
    end
  end

  def cancel_all
    current_user.scheduled_push_notifications.pending.find_each(&:cancel!)
    render json: { status: "cancelled" }
  end
end
