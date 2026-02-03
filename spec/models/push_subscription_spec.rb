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
describe PushSubscription do
  fixtures :users

  let(:user) { users(:john) }

  describe "validations" do
    it "is valid with valid attributes" do
      subscription =
        PushSubscription.new(
          user: user,
          endpoint: "https://example.com/push/123",
          p256dh: "test_p256dh_key",
          auth: "test_auth_key"
        )
      expect(subscription).to be_valid
    end

    it "is invalid without endpoint" do
      subscription =
        PushSubscription.new(
          user: user,
          endpoint: nil,
          p256dh: "test_p256dh_key",
          auth: "test_auth_key"
        )
      expect(subscription).not_to be_valid
      expect(subscription.errors[:endpoint]).to include("can't be blank")
    end

    it "is invalid without p256dh" do
      subscription =
        PushSubscription.new(
          user: user,
          endpoint: "https://example.com/push/123",
          p256dh: nil,
          auth: "test_auth_key"
        )
      expect(subscription).not_to be_valid
      expect(subscription.errors[:p256dh]).to include("can't be blank")
    end

    it "is invalid without auth" do
      subscription =
        PushSubscription.new(
          user: user,
          endpoint: "https://example.com/push/123",
          p256dh: "test_p256dh_key",
          auth: nil
        )
      expect(subscription).not_to be_valid
      expect(subscription.errors[:auth]).to include("can't be blank")
    end

    it "enforces unique endpoint per user" do
      PushSubscription.create!(
        user: user,
        endpoint: "https://example.com/push/123",
        p256dh: "test_p256dh_key",
        auth: "test_auth_key"
      )

      duplicate =
        PushSubscription.new(
          user: user,
          endpoint: "https://example.com/push/123",
          p256dh: "different_key",
          auth: "different_auth"
        )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:endpoint]).to include("has already been taken")
    end

    it "allows same endpoint for different users" do
      PushSubscription.create!(
        user: user,
        endpoint: "https://example.com/push/123",
        p256dh: "test_p256dh_key",
        auth: "test_auth_key"
      )

      other_user = users(:jane)
      subscription =
        PushSubscription.new(
          user: other_user,
          endpoint: "https://example.com/push/123",
          p256dh: "test_p256dh_key",
          auth: "test_auth_key"
        )
      expect(subscription).to be_valid
    end
  end

  describe "#touch_last_used" do
    it "updates last_used_at timestamp" do
      subscription =
        PushSubscription.create!(
          user: user,
          endpoint: "https://example.com/push/123",
          p256dh: "test_p256dh_key",
          auth: "test_auth_key"
        )

      expect(subscription.last_used_at).to be_nil

      subscription.touch_last_used
      expect(subscription.reload.last_used_at).to be_within(1.second).of(
        Time.current
      )
    end
  end

  describe "associations" do
    it "belongs to user" do
      subscription = PushSubscription.new
      expect(subscription).to respond_to(:user)
    end
  end
end
