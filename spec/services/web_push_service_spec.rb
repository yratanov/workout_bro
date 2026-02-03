describe WebPushService do
  fixtures :users

  let(:user) { users(:john) }
  let(:subscription) do
    PushSubscription.create!(
      user: user,
      endpoint: "https://example.com/push/123",
      p256dh: "test_p256dh_key",
      auth: "test_auth_key"
    )
  end

  describe "#initialize" do
    context "when VAPID is not configured" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("VAPID_PUBLIC_KEY").and_return(nil)
        allow(ENV).to receive(:[]).with("VAPID_PRIVATE_KEY").and_return(nil)
        allow(ENV).to receive(:[]).with("VAPID_SUBJECT").and_return(nil)
        allow(Rails.application.credentials).to receive(:dig).with(
          :vapid,
          :public_key
        ).and_return(nil)
        allow(Rails.application.credentials).to receive(:dig).with(
          :vapid,
          :private_key
        ).and_return(nil)
        allow(Rails.application.credentials).to receive(:dig).with(
          :vapid,
          :subject
        ).and_return(nil)
      end

      it "raises ConfigurationError" do
        expect { described_class.new }.to raise_error(
          WebPushService::ConfigurationError,
          /VAPID keys not configured/
        )
      end
    end
  end

  describe "#send_notification" do
    let(:service) { described_class.new }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("VAPID_PUBLIC_KEY").and_return(
        "test_public_key"
      )
      allow(ENV).to receive(:[]).with("VAPID_PRIVATE_KEY").and_return(
        "test_private_key"
      )
      allow(ENV).to receive(:[]).with("VAPID_SUBJECT").and_return(
        "mailto:test@example.com"
      )
    end

    context "when push succeeds" do
      before { allow(WebPush).to receive(:payload_send) }

      it "sends the notification" do
        service.send_notification(
          subscription: subscription,
          title: "Test Title",
          body: "Test Body"
        )

        expect(WebPush).to have_received(:payload_send).with(
          hash_including(
            endpoint: subscription.endpoint,
            p256dh: subscription.p256dh,
            auth: subscription.auth
          )
        )
      end

      it "updates last_used_at on subscription" do
        service.send_notification(
          subscription: subscription,
          title: "Test Title",
          body: "Test Body"
        )
        expect(subscription.reload.last_used_at).to be_within(1.second).of(
          Time.current
        )
      end

      it "returns true" do
        result =
          service.send_notification(
            subscription: subscription,
            title: "Test Title",
            body: "Test Body"
          )
        expect(result).to be true
      end
    end

    context "when subscription is expired" do
      before do
        allow(WebPush).to receive(:payload_send).and_raise(
          WebPush::ExpiredSubscription.new(double(body: ""), "")
        )
      end

      it "destroys the subscription" do
        expect {
          service.send_notification(
            subscription: subscription,
            title: "Test Title",
            body: "Test Body"
          )
        }.to change { PushSubscription.exists?(subscription.id) }.from(true).to(
          false
        )
      end

      it "returns false" do
        result =
          service.send_notification(
            subscription: subscription,
            title: "Test Title",
            body: "Test Body"
          )
        expect(result).to be false
      end
    end

    context "when subscription is invalid" do
      before do
        allow(WebPush).to receive(:payload_send).and_raise(
          WebPush::InvalidSubscription.new(double(body: ""), "")
        )
      end

      it "destroys the subscription" do
        expect {
          service.send_notification(
            subscription: subscription,
            title: "Test Title",
            body: "Test Body"
          )
        }.to change { PushSubscription.exists?(subscription.id) }.from(true).to(
          false
        )
      end
    end

    context "when push fails with response error" do
      before do
        allow(WebPush).to receive(:payload_send).and_raise(
          WebPush::ResponseError.new(double(body: "Server error"), "")
        )
      end

      it "raises DeliveryError" do
        expect {
          service.send_notification(
            subscription: subscription,
            title: "Test Title",
            body: "Test Body"
          )
        }.to raise_error(WebPushService::DeliveryError, /Push delivery failed/)
      end
    end
  end

  describe "#send_to_user" do
    let(:service) { described_class.new }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("VAPID_PUBLIC_KEY").and_return(
        "test_public_key"
      )
      allow(ENV).to receive(:[]).with("VAPID_PRIVATE_KEY").and_return(
        "test_private_key"
      )
      allow(ENV).to receive(:[]).with("VAPID_SUBJECT").and_return(
        "mailto:test@example.com"
      )
      allow(WebPush).to receive(:payload_send)
    end

    context "with multiple subscriptions" do
      let!(:subscription1) do
        PushSubscription.create!(
          user: user,
          endpoint: "https://example.com/push/1",
          p256dh: "key1",
          auth: "auth1"
        )
      end

      let!(:subscription2) do
        PushSubscription.create!(
          user: user,
          endpoint: "https://example.com/push/2",
          p256dh: "key2",
          auth: "auth2"
        )
      end

      it "sends to all subscriptions" do
        service.send_to_user(user: user, title: "Test", body: "Body")

        expect(WebPush).to have_received(:payload_send).twice
      end

      it "returns results summary" do
        result = service.send_to_user(user: user, title: "Test", body: "Body")

        expect(result).to eq({ sent: 2, failed: 0, expired: 0 })
      end
    end

    context "when some subscriptions expire" do
      let!(:valid_subscription) do
        PushSubscription.create!(
          user: user,
          endpoint: "https://example.com/push/valid",
          p256dh: "valid_key",
          auth: "valid_auth"
        )
      end

      let!(:expired_subscription) do
        PushSubscription.create!(
          user: user,
          endpoint: "https://example.com/push/expired",
          p256dh: "expired_key",
          auth: "expired_auth"
        )
      end

      before do
        call_count = 0
        allow(WebPush).to receive(:payload_send) do |args|
          call_count += 1
          if args[:endpoint] == "https://example.com/push/expired"
            raise WebPush::ExpiredSubscription.new(double(body: ""), "")
          end
        end
      end

      it "returns correct results" do
        result = service.send_to_user(user: user, title: "Test", body: "Body")

        expect(result).to eq({ sent: 1, failed: 0, expired: 1 })
      end
    end
  end

  describe ".vapid_public_key" do
    it "returns the public key from ENV first" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("VAPID_PUBLIC_KEY").and_return(
        "env_vapid_public_key"
      )

      expect(described_class.vapid_public_key).to eq("env_vapid_public_key")
    end

    it "falls back to credentials when ENV not set" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("VAPID_PUBLIC_KEY").and_return(nil)
      allow(Rails.application.credentials).to receive(:dig).with(
        :vapid,
        :public_key
      ).and_return("credentials_vapid_public_key")

      expect(described_class.vapid_public_key).to eq(
        "credentials_vapid_public_key"
      )
    end

    it "returns nil when not configured anywhere" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("VAPID_PUBLIC_KEY").and_return(nil)
      allow(Rails.application.credentials).to receive(:dig).with(
        :vapid,
        :public_key
      ).and_return(nil)

      expect(described_class.vapid_public_key).to be_nil
    end
  end
end
