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

    it "displays the AI trainer section" do
      get settings_ai_path
      expect(response.body).to include("AI Trainer")
    end

    it "shows warning when AI is not configured" do
      get settings_ai_path
      expect(response.body).to include("configure your AI provider")
    end

    it "does not show warning when AI is configured" do
      user.update!(ai_provider: "gemini", ai_model: "gemini-2.5-flash", ai_api_key: "test-key")
      get settings_ai_path
      expect(response.body).not_to include("configure your AI provider")
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

      it "saves the API key" do
        patch settings_ai_path,
              params: {
                user: {
                  ai_provider: "gemini",
                  ai_model: "gemini-2.5-pro",
                  ai_api_key: "test-api-key-123"
                }
              }

        user.reload
        expect(user.ai_api_key).to eq("test-api-key-123")
      end

      it "does not overwrite API key when blank" do
        user.update!(ai_api_key: "existing-key")

        patch settings_ai_path,
              params: {
                user: {
                  ai_provider: "gemini",
                  ai_api_key: ""
                }
              }

        user.reload
        expect(user.ai_api_key).to eq("existing-key")
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

  describe "POST /settings/ai/create_trainer" do
    it "creates an ai_trainer and enqueues job" do
      expect {
        post create_trainer_settings_ai_path,
             params: {
               ai_trainer: {
                 approach: "balanced",
                 communication_style: "motivational",
                 goal_general_fitness: "1",
                 train_on_existing_data: "1"
               }
             }
      }.to have_enqueued_job(CreateAiTrainerJob)

      expect(response).to redirect_to(settings_ai_path)
      expect(user.reload.ai_trainer).to be_present
      expect(user.ai_trainer.balanced?).to be true
      expect(user.ai_trainer.motivational?).to be true
    end

    it "updates existing ai_trainer" do
      post create_trainer_settings_ai_path,
           params: {
             ai_trainer: {
               approach: "tough_love",
               communication_style: "detailed"
             }
           }

      user.ai_trainer.reload
      expect(user.ai_trainer.tough_love?).to be true
      expect(user.ai_trainer.detailed?).to be true
    end
  end

  describe "GET /settings/ai/trainer_status" do
    it "returns trainer status as JSON" do
      user.ai_trainer.update!(status: :in_progress)

      get trainer_status_settings_ai_path, as: :json
      expect(response).to have_http_status(:success)

      data = response.parsed_body
      expect(data["status"]).to eq("in_progress")
    end

    it "returns pending status for default trainer" do
      get trainer_status_settings_ai_path, as: :json
      data = response.parsed_body
      expect(data["status"]).to eq("pending")
    end

    it "returns error_details on failure" do
      user.ai_trainer.update!(status: :failed, error_details: { message: "API key invalid" })

      get trainer_status_settings_ai_path, as: :json
      data = response.parsed_body
      expect(data["status"]).to eq("failed")
      expect(data["error_details"]["message"]).to eq("API key invalid")
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
