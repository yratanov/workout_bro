require "test_helper"

# == Schema Information
#
# Table name: push_subscriptions
# Database name: primary
#
#  id           :integer          not null, primary key
#  auth         :string           not null
#  endpoint     :string           not null
#  last_used_at :datetime
#  p256dh       :string           not null
#  user_agent   :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :integer          not null
#
# Indexes
#
#  index_push_subscriptions_on_user_id_and_endpoint  (user_id,endpoint) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#

class PushSubscriptionTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    subscription =
      PushSubscription.new(
        user: users(:john),
        endpoint: "https://example.com/push/123",
        p256dh: "test_p256dh_key",
        auth: "test_auth_key"
      )
    assert subscription.valid?
  end

  test "is invalid without endpoint" do
    subscription =
      PushSubscription.new(
        user: users(:john),
        endpoint: nil,
        p256dh: "test_p256dh_key",
        auth: "test_auth_key"
      )
    assert_not subscription.valid?
    assert_includes subscription.errors[:endpoint], "can't be blank"
  end

  test "is invalid without p256dh" do
    subscription =
      PushSubscription.new(
        user: users(:john),
        endpoint: "https://example.com/push/123",
        p256dh: nil,
        auth: "test_auth_key"
      )
    assert_not subscription.valid?
    assert_includes subscription.errors[:p256dh], "can't be blank"
  end

  test "is invalid without auth" do
    subscription =
      PushSubscription.new(
        user: users(:john),
        endpoint: "https://example.com/push/123",
        p256dh: "test_p256dh_key",
        auth: nil
      )
    assert_not subscription.valid?
    assert_includes subscription.errors[:auth], "can't be blank"
  end

  test "enforces unique endpoint per user" do
    PushSubscription.create!(
      user: users(:john),
      endpoint: "https://example.com/push/123",
      p256dh: "test_p256dh_key",
      auth: "test_auth_key"
    )

    duplicate =
      PushSubscription.new(
        user: users(:john),
        endpoint: "https://example.com/push/123",
        p256dh: "different_key",
        auth: "different_auth"
      )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:endpoint], "has already been taken"
  end

  test "allows same endpoint for different users" do
    PushSubscription.create!(
      user: users(:john),
      endpoint: "https://example.com/push/123",
      p256dh: "test_p256dh_key",
      auth: "test_auth_key"
    )

    subscription =
      PushSubscription.new(
        user: users(:jane),
        endpoint: "https://example.com/push/123",
        p256dh: "test_p256dh_key",
        auth: "test_auth_key"
      )
    assert subscription.valid?
  end

  test "touch_last_used updates last_used_at timestamp" do
    subscription =
      PushSubscription.create!(
        user: users(:john),
        endpoint: "https://example.com/push/123",
        p256dh: "test_p256dh_key",
        auth: "test_auth_key"
      )

    assert_nil subscription.last_used_at

    subscription.touch_last_used
    assert_in_delta Time.current, subscription.reload.last_used_at, 1.second
  end

  test "belongs to user" do
    subscription = PushSubscription.new
    assert subscription.respond_to?(:user)
  end
end
