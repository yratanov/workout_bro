describe "Settings::Weights" do
  fixtures :users

  let(:user) { users(:john) }

  before { sign_in(user) }

  describe "GET /settings/weights" do
    it "returns success" do
      get settings_weights_path
      expect(response).to have_http_status(:success)
    end

    it "displays the weight settings form" do
      get settings_weights_path
      expect(response.body).to include("Weight Settings")
    end
  end

  describe "PATCH /settings/weights" do
    context "with valid params" do
      it "updates weight_unit" do
        patch settings_weights_path, params: { user: { weight_unit: "lbs" } }

        user.reload
        expect(user.weight_unit).to eq("lbs")
        expect(response).to redirect_to(settings_weights_path)
      end

      it "updates weight_min" do
        patch settings_weights_path, params: { user: { weight_min: 5.0 } }

        user.reload
        expect(user.weight_min).to eq(5.0)
      end

      it "updates weight_max" do
        patch settings_weights_path, params: { user: { weight_max: 200.0 } }

        user.reload
        expect(user.weight_max).to eq(200.0)
      end

      it "updates weight_step" do
        patch settings_weights_path, params: { user: { weight_step: 5.0 } }

        user.reload
        expect(user.weight_step).to eq(5.0)
      end

      it "displays success message" do
        patch settings_weights_path, params: { user: { weight_unit: "lbs" } }

        follow_redirect!
        expect(response.body).to include("Weight settings updated successfully")
      end
    end

    context "with invalid params" do
      it "does not update with invalid weight_unit" do
        patch settings_weights_path,
              params: {
                user: {
                  weight_unit: "invalid"
                }
              }

        user.reload
        expect(user.weight_unit).to eq("kg")
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not update with zero weight_min" do
        patch settings_weights_path, params: { user: { weight_min: 0 } }

        user.reload
        expect(user.weight_min).to eq(2.5)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not update with weight_max less than weight_min" do
        patch settings_weights_path,
              params: {
                user: {
                  weight_min: 50,
                  weight_max: 25
                }
              }

        user.reload
        expect(user.weight_max).to eq(100.0)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not update with zero weight_step" do
        patch settings_weights_path, params: { user: { weight_step: 0 } }

        user.reload
        expect(user.weight_step).to eq(2.5)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context "when not authenticated" do
    before { delete session_path }

    it "redirects to login" do
      get settings_weights_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
