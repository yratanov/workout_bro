describe ScheduledPushNotification do
  fixtures :users

  let(:user) { users(:john) }

  describe "validations" do
    it "is valid with valid attributes" do
      notification =
        ScheduledPushNotification.new(
          user: user,
          job_id: SecureRandom.uuid,
          notification_type: "rest_timer",
          scheduled_for: 1.minute.from_now
        )
      expect(notification).to be_valid
    end

    it "is invalid without job_id" do
      notification =
        ScheduledPushNotification.new(
          user: user,
          job_id: nil,
          notification_type: "rest_timer",
          scheduled_for: 1.minute.from_now
        )
      expect(notification).not_to be_valid
      expect(notification.errors[:job_id]).to include("can't be blank")
    end

    it "is invalid without notification_type" do
      notification =
        ScheduledPushNotification.new(
          user: user,
          job_id: SecureRandom.uuid,
          notification_type: nil,
          scheduled_for: 1.minute.from_now
        )
      expect(notification).not_to be_valid
      expect(notification.errors[:notification_type]).to include(
        "can't be blank"
      )
    end

    it "is invalid without scheduled_for" do
      notification =
        ScheduledPushNotification.new(
          user: user,
          job_id: SecureRandom.uuid,
          notification_type: "rest_timer",
          scheduled_for: nil
        )
      expect(notification).not_to be_valid
      expect(notification.errors[:scheduled_for]).to include("can't be blank")
    end

    it "enforces unique job_id" do
      job_id = SecureRandom.uuid
      ScheduledPushNotification.create!(
        user: user,
        job_id: job_id,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.from_now
      )

      duplicate =
        ScheduledPushNotification.new(
          user: user,
          job_id: job_id,
          notification_type: "rest_timer",
          scheduled_for: 2.minutes.from_now
        )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:job_id]).to include("has already been taken")
    end
  end

  describe "status enum" do
    it "defaults to pending" do
      notification =
        ScheduledPushNotification.create!(
          user: user,
          job_id: SecureRandom.uuid,
          notification_type: "rest_timer",
          scheduled_for: 1.minute.from_now
        )
      expect(notification).to be_pending
    end

    it "can be set to sent" do
      notification =
        ScheduledPushNotification.create!(
          user: user,
          job_id: SecureRandom.uuid,
          notification_type: "rest_timer",
          scheduled_for: 1.minute.from_now,
          status: :sent
        )
      expect(notification).to be_sent
    end

    it "can be set to cancelled" do
      notification =
        ScheduledPushNotification.create!(
          user: user,
          job_id: SecureRandom.uuid,
          notification_type: "rest_timer",
          scheduled_for: 1.minute.from_now,
          status: :cancelled
        )
      expect(notification).to be_cancelled
    end
  end

  describe "#cancel!" do
    let(:notification) do
      ScheduledPushNotification.create!(
        user: user,
        job_id: SecureRandom.uuid,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.from_now
      )
    end

    context "when pending" do
      it "updates status to cancelled" do
        notification.cancel!
        expect(notification.reload).to be_cancelled
      end
    end

    context "when already sent" do
      before { notification.update!(status: :sent) }

      it "does not change status" do
        notification.cancel!
        expect(notification.reload).to be_sent
      end
    end

    context "when already cancelled" do
      before { notification.update!(status: :cancelled) }

      it "does not change status" do
        notification.cancel!
        expect(notification.reload).to be_cancelled
      end
    end
  end

  describe ".pending scope" do
    it "returns only pending notifications" do
      pending_notification =
        ScheduledPushNotification.create!(
          user: user,
          job_id: SecureRandom.uuid,
          notification_type: "rest_timer",
          scheduled_for: 1.minute.from_now,
          status: :pending
        )

      ScheduledPushNotification.create!(
        user: user,
        job_id: SecureRandom.uuid,
        notification_type: "rest_timer",
        scheduled_for: 1.minute.from_now,
        status: :sent
      )

      expect(ScheduledPushNotification.pending).to eq([pending_notification])
    end
  end
end
