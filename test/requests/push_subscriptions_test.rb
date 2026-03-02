require "test_helper"

class PushSubscriptionsTest < ActionDispatch::IntegrationTest
  setup { @user = users(:john) }

  # === POST /push_subscriptions (authenticated) ===

  test "POST /push_subscriptions creates a new subscription" do
    sign_in(@user)
    assert_difference "PushSubscription.count", 1 do
      post push_subscriptions_path, params: valid_subscription_params, as: :json
    end
  end

  test "POST /push_subscriptions returns created status" do
    sign_in(@user)
    post push_subscriptions_path, params: valid_subscription_params, as: :json
    assert_response :created
  end

  test "POST /push_subscriptions returns subscribed status" do
    sign_in(@user)
    post push_subscriptions_path, params: valid_subscription_params, as: :json
    assert_equal "subscribed", response.parsed_body["status"]
  end

  test "POST /push_subscriptions associates subscription with current user" do
    sign_in(@user)
    post push_subscriptions_path, params: valid_subscription_params, as: :json
    subscription = PushSubscription.last
    assert_equal @user, subscription.user
  end

  test "POST /push_subscriptions stores the user agent" do
    sign_in(@user)
    post push_subscriptions_path,
         params: valid_subscription_params,
         as: :json,
         headers: {
           "User-Agent" => "Test Browser"
         }
    subscription = PushSubscription.last
    assert_equal "Test Browser", subscription.user_agent
  end

  test "POST /push_subscriptions updates existing subscription" do
    sign_in(@user)
    PushSubscription.create!(
      user: @user,
      endpoint: "https://example.com/push/123",
      p256dh: "old_key",
      auth: "old_auth"
    )

    params = {
      subscription: {
        endpoint: "https://example.com/push/123",
        p256dh: "new_key",
        auth: "new_auth"
      }
    }
    assert_no_difference "PushSubscription.count" do
      post push_subscriptions_path, params: params, as: :json
    end

    subscription = @user.push_subscriptions.first
    assert_equal "new_key", subscription.p256dh
    assert_equal "new_auth", subscription.auth
  end

  test "POST /push_subscriptions returns unprocessable entity for invalid params" do
    sign_in(@user)
    params = { subscription: { endpoint: "" } }
    post push_subscriptions_path, params: params, as: :json
    assert_response :unprocessable_entity
  end

  test "POST /push_subscriptions returns error messages for invalid params" do
    sign_in(@user)
    params = { subscription: { endpoint: "" } }
    post push_subscriptions_path, params: params, as: :json
    assert response.parsed_body["errors"].present?
  end

  test "POST /push_subscriptions redirects when not authenticated" do
    params = {
      subscription: {
        endpoint: "https://example.com/push/123",
        p256dh: "key",
        auth: "auth"
      }
    }
    post push_subscriptions_path, params: params, as: :json
    assert_response :redirect
  end

  # === DELETE /push_subscriptions ===

  test "DELETE /push_subscriptions destroys the subscription" do
    sign_in(@user)
    subscription =
      PushSubscription.create!(
        user: @user,
        endpoint: "https://example.com/push/123",
        p256dh: "key",
        auth: "auth"
      )
    assert_difference "PushSubscription.count", -1 do
      delete push_subscriptions_path,
             params: {
               endpoint: subscription.endpoint
             },
             as: :json
    end
  end

  test "DELETE /push_subscriptions returns success status" do
    sign_in(@user)
    subscription =
      PushSubscription.create!(
        user: @user,
        endpoint: "https://example.com/push/123",
        p256dh: "key",
        auth: "auth"
      )
    delete push_subscriptions_path,
           params: {
             endpoint: subscription.endpoint
           },
           as: :json
    assert_response :ok
    assert_equal "unsubscribed", response.parsed_body["status"]
  end

  test "DELETE /push_subscriptions returns success when subscription does not exist" do
    sign_in(@user)
    delete push_subscriptions_path,
           params: {
             endpoint: "nonexistent"
           },
           as: :json
    assert_response :ok
  end

  # === GET /push_subscriptions/vapid_public_key ===

  test "GET /push_subscriptions/vapid_public_key returns the public key when configured" do
    sign_in(@user)
    WebPushService.stubs(:vapid_public_key).returns("test_vapid_public_key")
    get vapid_public_key_push_subscriptions_path, as: :json
    assert_response :ok
    assert_equal "test_vapid_public_key",
                 response.parsed_body["vapid_public_key"]
  end

  test "GET /push_subscriptions/vapid_public_key returns service unavailable when not configured" do
    sign_in(@user)
    WebPushService.stubs(:vapid_public_key).returns(nil)
    get vapid_public_key_push_subscriptions_path, as: :json
    assert_response :service_unavailable
    assert_equal "VAPID not configured", response.parsed_body["error"]
  end

  test "GET /push_subscriptions/vapid_public_key redirects when not authenticated" do
    get vapid_public_key_push_subscriptions_path, as: :json
    assert_response :redirect
  end

  private

  def valid_subscription_params
    {
      subscription: {
        endpoint: "https://example.com/push/123",
        p256dh: "test_p256dh_key",
        auth: "test_auth_key"
      }
    }
  end
end
