require "test_helper"

class WebPushServiceTest < ActiveSupport::TestCase
  test "raises ConfigurationError when VAPID is not configured" do
    ENV.stubs(:[]).with(anything).returns(nil)
    ENV.stubs(:[]).with("VAPID_PUBLIC_KEY").returns(nil)
    ENV.stubs(:[]).with("VAPID_PRIVATE_KEY").returns(nil)
    ENV.stubs(:[]).with("VAPID_SUBJECT").returns(nil)
    Rails
      .application
      .credentials
      .stubs(:dig)
      .with(:vapid, :public_key)
      .returns(nil)
    Rails
      .application
      .credentials
      .stubs(:dig)
      .with(:vapid, :private_key)
      .returns(nil)
    Rails
      .application
      .credentials
      .stubs(:dig)
      .with(:vapid, :subject)
      .returns(nil)

    assert_raises(WebPushService::ConfigurationError) { WebPushService.new }
  end

  test "sends the notification successfully" do
    service = build_service
    subscription = create_subscription

    WebPush.expects(:payload_send).with(
      has_entries(
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh,
        auth: subscription.auth
      )
    )

    service.send_notification(
      subscription: subscription,
      title: "Test Title",
      body: "Test Body"
    )
  end

  test "updates last_used_at on subscription after send" do
    service = build_service
    subscription = create_subscription
    WebPush.stubs(:payload_send)

    service.send_notification(
      subscription: subscription,
      title: "Test Title",
      body: "Test Body"
    )
    assert_in_delta Time.current, subscription.reload.last_used_at, 1.second
  end

  test "returns true on successful send" do
    service = build_service
    subscription = create_subscription
    WebPush.stubs(:payload_send)

    result =
      service.send_notification(
        subscription: subscription,
        title: "Test Title",
        body: "Test Body"
      )
    assert result
  end

  test "destroys subscription when expired" do
    service = build_service
    subscription = create_subscription
    WebPush.stubs(:payload_send).raises(
      WebPush::ExpiredSubscription.new(stub(body: ""), "")
    )

    service.send_notification(
      subscription: subscription,
      title: "Test Title",
      body: "Test Body"
    )
    refute PushSubscription.exists?(subscription.id)
  end

  test "returns false when subscription is expired" do
    service = build_service
    subscription = create_subscription
    WebPush.stubs(:payload_send).raises(
      WebPush::ExpiredSubscription.new(stub(body: ""), "")
    )

    result =
      service.send_notification(
        subscription: subscription,
        title: "Test Title",
        body: "Test Body"
      )
    refute result
  end

  test "destroys subscription when invalid" do
    service = build_service
    subscription = create_subscription
    WebPush.stubs(:payload_send).raises(
      WebPush::InvalidSubscription.new(stub(body: ""), "")
    )

    service.send_notification(
      subscription: subscription,
      title: "Test Title",
      body: "Test Body"
    )
    refute PushSubscription.exists?(subscription.id)
  end

  test "raises DeliveryError on response error" do
    service = build_service
    subscription = create_subscription
    WebPush.stubs(:payload_send).raises(
      WebPush::ResponseError.new(stub(body: "Server error"), "")
    )

    assert_raises(WebPushService::DeliveryError) do
      service.send_notification(
        subscription: subscription,
        title: "Test Title",
        body: "Test Body"
      )
    end
  end

  test "sends to all subscriptions for user" do
    service = build_service
    user = users(:john)
    PushSubscription.create!(
      user: user,
      endpoint: "https://example.com/push/1",
      p256dh: "key1",
      auth: "auth1"
    )
    PushSubscription.create!(
      user: user,
      endpoint: "https://example.com/push/2",
      p256dh: "key2",
      auth: "auth2"
    )

    WebPush.stubs(:payload_send)

    result = service.send_to_user(user: user, title: "Test", body: "Body")
    assert_equal({ sent: 2, failed: 0, expired: 0 }, result)
  end

  test "returns correct results when some subscriptions expire" do
    service = build_service
    user = users(:john)
    PushSubscription.create!(
      user: user,
      endpoint: "https://example.com/push/valid",
      p256dh: "valid_key",
      auth: "valid_auth"
    )
    PushSubscription.create!(
      user: user,
      endpoint: "https://example.com/push/expired",
      p256dh: "expired_key",
      auth: "expired_auth"
    )

    WebPush
      .stubs(:payload_send)
      .with { |args| args[:endpoint] == "https://example.com/push/expired" }
      .raises(WebPush::ExpiredSubscription.new(stub(body: ""), ""))
    WebPush
      .stubs(:payload_send)
      .with { |args| args[:endpoint] == "https://example.com/push/valid" }

    result = service.send_to_user(user: user, title: "Test", body: "Body")
    assert_equal({ sent: 1, failed: 0, expired: 1 }, result)
  end

  test "vapid_public_key returns key from ENV first" do
    ENV.stubs(:[]).with(anything).returns(nil)
    ENV.stubs(:[]).with("VAPID_PUBLIC_KEY").returns("env_vapid_public_key")

    assert_equal "env_vapid_public_key", WebPushService.vapid_public_key
  end

  test "vapid_public_key falls back to credentials when ENV not set" do
    ENV.stubs(:[]).with(anything).returns(nil)
    ENV.stubs(:[]).with("VAPID_PUBLIC_KEY").returns(nil)
    Rails
      .application
      .credentials
      .stubs(:dig)
      .with(:vapid, :public_key)
      .returns("credentials_vapid_public_key")

    assert_equal "credentials_vapid_public_key", WebPushService.vapid_public_key
  end

  test "vapid_public_key returns nil when not configured anywhere" do
    ENV.stubs(:[]).with(anything).returns(nil)
    ENV.stubs(:[]).with("VAPID_PUBLIC_KEY").returns(nil)
    Rails
      .application
      .credentials
      .stubs(:dig)
      .with(:vapid, :public_key)
      .returns(nil)

    assert_nil WebPushService.vapid_public_key
  end

  private

  def build_service
    ENV.stubs(:[]).with(anything).returns(nil)
    ENV.stubs(:[]).with("VAPID_PUBLIC_KEY").returns("test_public_key")
    ENV.stubs(:[]).with("VAPID_PRIVATE_KEY").returns("test_private_key")
    ENV.stubs(:[]).with("VAPID_SUBJECT").returns("mailto:test@example.com")
    WebPushService.new
  end

  def create_subscription
    PushSubscription.create!(
      user: users(:john),
      endpoint: "https://example.com/push/123",
      p256dh: "test_p256dh_key",
      auth: "test_auth_key"
    )
  end
end
