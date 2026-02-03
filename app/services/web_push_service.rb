class WebPushService
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class DeliveryError < Error; end

  def initialize
    validate_configuration!
  end

  def send_notification(subscription:, title:, body:, data: {})
    message = {
      title: title,
      options: {
        body: body,
        icon: "/icon2.png",
        badge: "/icon2.png",
        tag: data[:tag] || "workout-bro",
        data: data,
        requireInteraction: true
      }
    }

    WebPush.payload_send(
      message: message.to_json,
      endpoint: subscription.endpoint,
      p256dh: subscription.p256dh,
      auth: subscription.auth,
      vapid: vapid_options,
      ssl_timeout: 5,
      open_timeout: 5,
      read_timeout: 5
    )

    subscription.touch_last_used
    true
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    subscription.destroy
    false
  rescue WebPush::ResponseError => e
    raise DeliveryError, "Push delivery failed: #{e.message}"
  end

  def send_to_user(user:, title:, body:, data: {})
    results = { sent: 0, failed: 0, expired: 0 }

    user.push_subscriptions.find_each do |subscription|
      if send_notification(subscription: subscription, title: title, body: body, data: data)
        results[:sent] += 1
      else
        results[:expired] += 1
      end
    rescue DeliveryError
      results[:failed] += 1
    end

    results
  end

  def self.vapid_public_key
    ENV["VAPID_PUBLIC_KEY"] || Rails.application.credentials.dig(:vapid, :public_key)
  end

  private

  def validate_configuration!
    unless vapid_configured?
      raise ConfigurationError, "VAPID keys not configured. Set VAPID_PUBLIC_KEY and VAPID_PRIVATE_KEY environment variables, or run `bin/rails vapid:generate` and add to credentials."
    end
  end

  def vapid_configured?
    vapid_options[:public_key].present? && vapid_options[:private_key].present?
  end

  def vapid_options
    @vapid_options ||= {
      subject: ENV["VAPID_SUBJECT"] || Rails.application.credentials.dig(:vapid, :subject) || "mailto:admin@workout-bro.com",
      public_key: ENV["VAPID_PUBLIC_KEY"] || Rails.application.credentials.dig(:vapid, :public_key),
      private_key: ENV["VAPID_PRIVATE_KEY"] || Rails.application.credentials.dig(:vapid, :private_key)
    }
  end
end
