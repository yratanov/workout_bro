describe "ScheduledPushNotifications" do
  fixtures :users

  let(:user) { users(:john) }

  describe "POST /scheduled_push_notifications" do
    context "when authenticated" do
      before { sign_in(user) }

      context "with valid delay" do
        it "creates a scheduled notification" do
          expect {
            post scheduled_push_notifications_path,
                 params: {
                   delay_seconds: 60
                 },
                 as: :json
          }.to change(ScheduledPushNotification, :count).by(1)
        end

        it "returns success status" do
          post scheduled_push_notifications_path,
               params: {
                 delay_seconds: 60
               },
               as: :json
          expect(response).to have_http_status(:created)
        end

        it "returns the notification id" do
          post scheduled_push_notifications_path,
               params: {
                 delay_seconds: 60
               },
               as: :json
          expect(response.parsed_body["id"]).to be_present
        end

        it "returns the scheduled_for time" do
          post scheduled_push_notifications_path,
               params: {
                 delay_seconds: 60
               },
               as: :json
          scheduled_for = Time.zone.parse(response.parsed_body["scheduled_for"])
          expect(scheduled_for).to be_within(2.seconds).of(
            Time.current + 60.seconds
          )
        end

        it "enqueues a job" do
          expect {
            post scheduled_push_notifications_path,
                 params: {
                   delay_seconds: 60
                 },
                 as: :json
          }.to have_enqueued_job(SendPushNotificationJob)
        end
      end

      context "with invalid delay" do
        it "returns error for zero delay" do
          post scheduled_push_notifications_path,
               params: {
                 delay_seconds: 0
               },
               as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body["error"]).to eq("Invalid delay")
        end

        it "returns error for negative delay" do
          post scheduled_push_notifications_path,
               params: {
                 delay_seconds: -10
               },
               as: :json
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post scheduled_push_notifications_path,
             params: {
               delay_seconds: 60
             },
             as: :json
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "DELETE /scheduled_push_notifications/:id" do
    context "when authenticated" do
      before { sign_in(user) }

      context "when notification exists and is pending" do
        let!(:notification) do
          ScheduledPushNotification.create!(
            user: user,
            job_id: SecureRandom.uuid,
            notification_type: "rest_timer",
            scheduled_for: 1.minute.from_now,
            status: :pending
          )
        end

        it "cancels the notification" do
          delete scheduled_push_notification_path(notification), as: :json
          expect(notification.reload).to be_cancelled
        end

        it "returns success status" do
          delete scheduled_push_notification_path(notification), as: :json
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body["status"]).to eq("cancelled")
        end
      end

      context "when notification is already sent" do
        let!(:notification) do
          ScheduledPushNotification.create!(
            user: user,
            job_id: SecureRandom.uuid,
            notification_type: "rest_timer",
            scheduled_for: 1.minute.ago,
            status: :sent
          )
        end

        it "returns not found" do
          delete scheduled_push_notification_path(notification), as: :json
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when notification belongs to another user" do
        let(:other_user) { users(:jane) }
        let!(:notification) do
          ScheduledPushNotification.create!(
            user: other_user,
            job_id: SecureRandom.uuid,
            notification_type: "rest_timer",
            scheduled_for: 1.minute.from_now,
            status: :pending
          )
        end

        it "returns not found" do
          delete scheduled_push_notification_path(notification), as: :json
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when notification does not exist" do
        it "returns not found" do
          delete scheduled_push_notification_path(id: 999_999), as: :json
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "DELETE /scheduled_push_notifications/cancel_all" do
    context "when authenticated" do
      before { sign_in(user) }

      context "with pending notifications" do
        let!(:notification1) do
          ScheduledPushNotification.create!(
            user: user,
            job_id: SecureRandom.uuid,
            notification_type: "rest_timer",
            scheduled_for: 1.minute.from_now,
            status: :pending
          )
        end

        let!(:notification2) do
          ScheduledPushNotification.create!(
            user: user,
            job_id: SecureRandom.uuid,
            notification_type: "rest_timer",
            scheduled_for: 2.minutes.from_now,
            status: :pending
          )
        end

        it "cancels all pending notifications" do
          delete cancel_all_scheduled_push_notifications_path, as: :json

          expect(notification1.reload).to be_cancelled
          expect(notification2.reload).to be_cancelled
        end

        it "returns success status" do
          delete cancel_all_scheduled_push_notifications_path, as: :json
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body["status"]).to eq("cancelled")
        end
      end

      context "with no pending notifications" do
        it "returns success status" do
          delete cancel_all_scheduled_push_notifications_path, as: :json
          expect(response).to have_http_status(:ok)
        end
      end

      context "does not cancel other user's notifications" do
        let(:other_user) { users(:jane) }
        let!(:other_notification) do
          ScheduledPushNotification.create!(
            user: other_user,
            job_id: SecureRandom.uuid,
            notification_type: "rest_timer",
            scheduled_for: 1.minute.from_now,
            status: :pending
          )
        end

        it "leaves other user's notifications unchanged" do
          delete cancel_all_scheduled_push_notifications_path, as: :json
          expect(other_notification.reload).to be_pending
        end
      end
    end
  end
end
