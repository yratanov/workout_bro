describe "Settings::Ai" do
  fixtures :users

  let(:user) { users(:john) }

  before { sign_in(user) }

  describe "GET /settings/ai" do
    it "returns success" do
      get settings_ai_path
      expect(response).to have_http_status(:success)
    end

    it "displays the AI settings form" do
      get settings_ai_path
      expect(response.body).to include("AI Settings")
    end
  end

  describe "PATCH /settings/ai" do
    context "with valid params" do
      it "updates ai_provider and ai_model" do
        patch settings_ai_path,
              params: {
                user: {
                  ai_provider: "gemini",
                  ai_model: "gemini-2.5-pro"
                }
              }

        user.reload
        expect(user.ai_provider).to eq("gemini")
        expect(user.ai_model).to eq("gemini-2.5-pro")
        expect(response).to redirect_to(settings_ai_path)
      end

      it "clears ai_provider and ai_model" do
        user.update!(ai_provider: "gemini", ai_model: "gemini-2.5-pro")

        patch settings_ai_path,
              params: {
                user: {
                  ai_provider: "",
                  ai_model: ""
                }
              }

        user.reload
        expect(user.ai_provider).to eq("")
        expect(user.ai_model).to eq("")
      end

      it "displays success message" do
        patch settings_ai_path,
              params: {
                user: {
                  ai_provider: "gemini",
                  ai_model: "gemini-2.5-flash"
                }
              }

        follow_redirect!
        expect(response.body).to include("AI settings updated successfully")
      end
    end
  end

  context "when not authenticated" do
    before { delete session_path }

    it "redirects to login" do
      get settings_ai_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
