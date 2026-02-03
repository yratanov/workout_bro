describe SendPushNotificationJob do
  fixtures :users

  let(:user) { users(:john) }
  let(:notification) do
    ScheduledPushNotification.create!(
      user: user,
      job_id: SecureRandom.uuid,
      notification_type: "rest_timer",
      scheduled_for: 1.minute.from_now
    )
  end

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

  describe "#perform" do
    context "when notification exists and is pending" do
      let!(:subscription) do
        PushSubscription.create!(
          user: user,
          endpoint: "https://example.com/push/123",
          p256dh: "test_key",
          auth: "test_auth"
        )
      end

      before { allow(WebPush).to receive(:payload_send) }

      it "sends the push notification" do
        described_class.perform_now(notification.id)

        expect(WebPush).to have_received(:payload_send)
      end

      it "updates notification status to sent" do
        described_class.perform_now(notification.id)

        expect(notification.reload).to be_sent
      end
    end

    context "when notification does not exist" do
      it "returns early without error" do
        expect { described_class.perform_now(999_999) }.not_to raise_error
      end
    end

    context "when notification is already sent" do
      before { notification.update!(status: :sent) }

      it "does not send push" do
        allow(WebPush).to receive(:payload_send)

        described_class.perform_now(notification.id)

        expect(WebPush).not_to have_received(:payload_send)
      end
    end

    context "when notification is cancelled" do
      before { notification.update!(status: :cancelled) }

      it "does not send push" do
        allow(WebPush).to receive(:payload_send)

        described_class.perform_now(notification.id)

        expect(WebPush).not_to have_received(:payload_send)
      end
    end

    context "when user has no push subscriptions" do
      it "does not attempt to send" do
        allow(WebPush).to receive(:payload_send)

        described_class.perform_now(notification.id)

        expect(WebPush).not_to have_received(:payload_send)
      end
    end

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

        PushSubscription.create!(
          user: user,
          endpoint: "https://example.com/push/123",
          p256dh: "test_key",
          auth: "test_auth"
        )
      end

      it "cancels the notification" do
        described_class.perform_now(notification.id)

        expect(notification.reload).to be_cancelled
      end

      it "does not raise an error" do
        expect {
          described_class.perform_now(notification.id)
        }.not_to raise_error
      end
    end
  end
end
