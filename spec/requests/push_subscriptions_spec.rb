describe "PushSubscriptions" do
  fixtures :users

  let(:user) { users(:john) }

  describe "POST /push_subscriptions" do
    context "when authenticated" do
      before { sign_in(user) }

      context "with valid params" do
        let(:valid_params) do
          {
            subscription: {
              endpoint: "https://example.com/push/123",
              p256dh: "test_p256dh_key",
              auth: "test_auth_key"
            }
          }
        end

        it "creates a new subscription" do
          expect {
            post push_subscriptions_path, params: valid_params, as: :json
          }.to change(PushSubscription, :count).by(1)
        end

        it "returns success status" do
          post push_subscriptions_path, params: valid_params, as: :json
          expect(response).to have_http_status(:created)
        end

        it "returns subscribed status" do
          post push_subscriptions_path, params: valid_params, as: :json
          expect(response.parsed_body["status"]).to eq("subscribed")
        end

        it "associates subscription with current user" do
          post push_subscriptions_path, params: valid_params, as: :json
          subscription = PushSubscription.last
          expect(subscription.user).to eq(user)
        end

        it "stores the user agent" do
          post push_subscriptions_path,
               params: valid_params,
               as: :json,
               headers: {
                 "User-Agent" => "Test Browser"
               }
          subscription = PushSubscription.last
          expect(subscription.user_agent).to eq("Test Browser")
        end
      end

      context "when subscription already exists" do
        before do
          PushSubscription.create!(
            user: user,
            endpoint: "https://example.com/push/123",
            p256dh: "old_key",
            auth: "old_auth"
          )
        end

        it "updates existing subscription" do
          params = {
            subscription: {
              endpoint: "https://example.com/push/123",
              p256dh: "new_key",
              auth: "new_auth"
            }
          }

          expect {
            post push_subscriptions_path, params: params, as: :json
          }.not_to change(PushSubscription, :count)

          subscription = user.push_subscriptions.first
          expect(subscription.p256dh).to eq("new_key")
          expect(subscription.auth).to eq("new_auth")
        end
      end

      context "with invalid params" do
        it "returns unprocessable entity" do
          params = { subscription: { endpoint: "" } }
          post push_subscriptions_path, params: params, as: :json
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns error messages" do
          params = { subscription: { endpoint: "" } }
          post push_subscriptions_path, params: params, as: :json
          expect(response.parsed_body["errors"]).to be_present
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        params = {
          subscription: {
            endpoint: "https://example.com/push/123",
            p256dh: "key",
            auth: "auth"
          }
        }
        post push_subscriptions_path, params: params, as: :json
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "DELETE /push_subscriptions" do
    context "when authenticated" do
      before { sign_in(user) }

      context "when subscription exists" do
        let!(:subscription) do
          PushSubscription.create!(
            user: user,
            endpoint: "https://example.com/push/123",
            p256dh: "key",
            auth: "auth"
          )
        end

        it "destroys the subscription" do
          expect {
            delete push_subscriptions_path,
                   params: {
                     endpoint: subscription.endpoint
                   },
                   as: :json
          }.to change(PushSubscription, :count).by(-1)
        end

        it "returns success status" do
          delete push_subscriptions_path,
                 params: {
                   endpoint: subscription.endpoint
                 },
                 as: :json
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body["status"]).to eq("unsubscribed")
        end
      end

      context "when subscription does not exist" do
        it "returns success status anyway" do
          delete push_subscriptions_path,
                 params: {
                   endpoint: "nonexistent"
                 },
                 as: :json
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "GET /push_subscriptions/vapid_public_key" do
    context "when authenticated" do
      before { sign_in(user) }

      context "when VAPID is configured" do
        before do
          allow(WebPushService).to receive(:vapid_public_key).and_return(
            "test_vapid_public_key"
          )
        end

        it "returns the public key" do
          get vapid_public_key_push_subscriptions_path, as: :json
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body["vapid_public_key"]).to eq(
            "test_vapid_public_key"
          )
        end
      end

      context "when VAPID is not configured" do
        before do
          allow(WebPushService).to receive(:vapid_public_key).and_return(nil)
        end

        it "returns service unavailable" do
          get vapid_public_key_push_subscriptions_path, as: :json
          expect(response).to have_http_status(:service_unavailable)
          expect(response.parsed_body["error"]).to eq("VAPID not configured")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get vapid_public_key_push_subscriptions_path, as: :json
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
