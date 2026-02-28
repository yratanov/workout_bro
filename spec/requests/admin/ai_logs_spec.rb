describe "Admin::AiLogs" do
  fixtures :all

  let(:admin_user) { users(:john) }
  let(:regular_user) { users(:jane) }

  describe "as admin" do
    before { sign_in(admin_user) }

    describe "GET /admin/ai_logs" do
      it "returns success" do
        get admin_ai_logs_path
        expect(response).to have_http_status(:success)
      end

      it "displays the AI logs page" do
        get admin_ai_logs_path
        expect(response.body).to include(I18n.t("admin.ai_logs.index.ai_logs"))
      end

      it "displays AI logs when present" do
        AiLog.create!(
          user: admin_user,
          action: "create_trainer",
          model: "gemini-2.0-flash",
          prompt: "Test prompt",
          response: "Test response",
          duration_ms: 1234
        )

        get admin_ai_logs_path
        expect(response.body).to include("create_trainer")
        expect(response.body).to include("gemini-2.0-flash")
        expect(response.body).to include("1234ms")
      end

      it "displays AI logs in descending order by created_at" do
        AiLog.create!(
          user: admin_user,
          action: "old_action",
          model: "gemini-2.0-flash",
          created_at: 1.hour.ago
        )
        AiLog.create!(
          user: admin_user,
          action: "new_action",
          model: "gemini-2.0-flash",
          created_at: Time.current
        )

        get admin_ai_logs_path
        expect(response.body.index("new_action")).to be <
          response.body.index("old_action")
      end

      it "displays error badge for failed requests" do
        AiLog.create!(
          user: admin_user,
          action: "create_trainer",
          model: "gemini-2.0-flash",
          error: "API rate limit exceeded"
        )

        get admin_ai_logs_path
        expect(response.body).to include(I18n.t("admin.ai_logs.index.failed"))
        expect(response.body).to include("API rate limit exceeded")
      end

      it "displays user email" do
        AiLog.create!(
          user: admin_user,
          action: "workout_feedback",
          model: "gemini-2.0-flash"
        )

        get admin_ai_logs_path
        expect(response.body).to include(admin_user.email_address)
      end

      it "displays expandable prompt section" do
        AiLog.create!(
          user: admin_user,
          action: "create_trainer",
          model: "gemini-2.0-flash",
          prompt: "Generate a trainer profile"
        )

        get admin_ai_logs_path
        expect(response.body).to include(
          I18n.t("admin.ai_logs.index.show_prompt")
        )
        expect(response.body).to include("Generate a trainer profile")
      end

      it "displays expandable response section" do
        AiLog.create!(
          user: admin_user,
          action: "create_trainer",
          model: "gemini-2.0-flash",
          response: "Here is your trainer"
        )

        get admin_ai_logs_path
        expect(response.body).to include(
          I18n.t("admin.ai_logs.index.show_response")
        )
        expect(response.body).to include("Here is your trainer")
      end

      it "shows empty state when no logs" do
        get admin_ai_logs_path
        expect(response.body).to include(I18n.t("admin.ai_logs.index.no_logs"))
      end

      it "paginates logs" do
        30.times do |i|
          AiLog.create!(
            user: admin_user,
            action: "action_#{i}",
            model: "gemini-2.0-flash"
          )
        end

        get admin_ai_logs_path
        expect(response.body).to include("action_29")
        expect(response.body).not_to include("action_0")
      end
    end
  end

  describe "as regular user" do
    before { sign_in(regular_user) }

    it "redirects from GET /admin/ai_logs" do
      get admin_ai_logs_path
      expect(response).to redirect_to(root_path)
    end

    it "shows admin required flash message" do
      get admin_ai_logs_path
      follow_redirect!
      expect(response.body).to include(
        I18n.t("controllers.application.admin_required")
      )
    end
  end

  describe "when not authenticated" do
    it "redirects to login" do
      get admin_ai_logs_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
